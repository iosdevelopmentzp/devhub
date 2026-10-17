import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class MockServerStore: MockTrafficLookup {
    private(set) var settings: [Simulator.ID: MockSimulatorSettings] {
        didSet { store.encode(settings, forKey: Keys.settings) }
    }
    private(set) var states: [Simulator.ID: MockServerState] = [:]
    private(set) var exchanges: [Simulator.ID: [NetworkRequest]] = [:]
    private(set) var applyingIDs: Set<Simulator.ID> = []
    private(set) var errors: [Simulator.ID: String] = [:]

    @ObservationIgnored private let relaunch: RelaunchWithMocksUseCase
    @ObservationIgnored private let server: any MockServerRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let identity: any IdentityLookup
    @ObservationIgnored private let sets: any MockSetLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    static let maxExchanges = 2_000

    init(
        relaunch: RelaunchWithMocksUseCase,
        server: any MockServerRepository,
        session: ProjectSession,
        simulators: any SimulatorLookup,
        identity: any IdentityLookup,
        sets: any MockSetLookup,
        activity: ActivityLog,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.relaunch = relaunch
        self.server = server
        self.session = session
        self.simulators = simulators
        self.identity = identity
        self.sets = sets
        self.activity = activity
        self.store = store
        settings = store.decode([Simulator.ID: MockSimulatorSettings].self, forKey: Keys.settings) ?? [:]
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                stopAll()
            case .mockSetChanged(let id):
                pushRules(of: id)
            case .appLaunched(let id):
                Task { await self.sync(id) }
            case .buildFinished(let id, _):
                Task { await self.sync(id) }
            default:
                break
            }
        }
    }

    func settings(for id: Simulator.ID) -> MockSimulatorSettings {
        settings[id] ?? .off
    }

    func isApplying(_ id: Simulator.ID) -> Bool {
        applyingIDs.contains(id)
    }

    func needsApply(_ id: Simulator.ID) -> Bool {
        let wanted = settings(for: id)
        let running = states[id]
        guard wanted.mode == (running?.mode ?? .off) else { return true }
        return wanted.mode == .mock && wanted.setID != running?.setID
    }

    func setMode(_ mode: MockMode, for id: Simulator.ID) {
        var current = settings(for: id)
        current.mode = mode
        settings[id] = current
    }

    func selectSet(_ setID: MockSet.ID?, for id: Simulator.ID) {
        var current = settings(for: id)
        current.setID = setID
        settings[id] = current
    }

    // MARK: Apply

    func apply(on id: Simulator.ID) {
        guard applyingIDs.contains(id) == false else { return }
        let wanted = settings(for: id)
        let request = relaunchRequest(for: id, wanted: wanted)
        let name = simulators.simulator(id: id)?.name ?? id
        applyingIDs.insert(id)
        errors[id] = nil
        Task { [weak self] in
            guard let self else { return }
            do {
                let state = try await relaunch.execute(request) { [weak self] exchange in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        receive(exchange, for: id)
                    }
                }
                states[id] = state
                rememberUpstream(for: id, request: request)
                activity.log(title(for: wanted.mode, on: name), detail: detail(for: state), outcome: .success)
            } catch {
                errors[id] = error.localizedDescription
                if await server.port(udid: id) == nil {
                    states[id] = nil
                }
                activity.log("Could not apply network mocks on \(name)", detail: error.localizedDescription, outcome: .failure)
            }
            applyingIDs.remove(id)
        }
    }

    func restoreServers() {
        let saved = settings.compactMap { id, setting -> (id: Simulator.ID, setting: MockSimulatorSettings, upstream: URL)? in
            guard setting.mode != .off, let upstream = setting.upstream.flatMap(URL.init(string:)) else { return nil }
            return (id, setting, upstream)
        }
        guard saved.isEmpty == false else { return }
        Task { [weak self] in
            guard let self else { return }
            var restored: [Int] = []
            for item in saved {
                let rules = item.setting.mode == .mock ? item.setting.setID.flatMap(sets.set(id:))?.rules ?? [] : []
                do {
                    let port = try await server.start(udid: item.id, upstream: item.upstream, rules: rules) { [weak self] exchange in
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            receive(exchange, for: item.id)
                        }
                    }
                    states[item.id] = MockServerState(
                        mode: item.setting.mode,
                        setID: item.setting.mode == .mock ? item.setting.setID : nil,
                        upstreamHost: item.upstream.host ?? item.upstream.absoluteString,
                        status: .running(port: port)
                    )
                    restored.append(port)
                } catch {
                    errors[item.id] = error.localizedDescription
                    activity.log("Could not restore the mock server", detail: error.localizedDescription, outcome: .failure)
                }
            }
            guard restored.isEmpty == false else { return }
            activity.log(
                "Mock servers restored: \(restored.count)",
                detail: "Ports \(restored.map(String.init).joined(separator: ", ")). Apps launched from DevHub before keep working.",
                outcome: .info
            )
        }
    }

    // MARK: Traffic

    func isIntercepting(_ id: Simulator.ID) -> Bool {
        states[id]?.port != nil
    }

    func exchanges(for id: Simulator.ID) -> [NetworkRequest] {
        exchanges[id] ?? []
    }

    func clearExchanges(for id: Simulator.ID) {
        exchanges[id] = nil
    }

    func receive(_ exchange: NetworkRequest, for id: Simulator.ID) {
        var list = exchanges[id] ?? []
        list.append(exchange)
        if list.count > Self.maxExchanges {
            list.removeFirst(list.count - Self.maxExchanges)
        }
        exchanges[id] = list
    }

    // MARK: Helpers

    private func sync(_ id: Simulator.ID) async {
        let port = await server.port(udid: id)
        let upstream = await server.upstream(udid: id)
        guard var state = states[id] else { return }
        guard let port, let upstream else {
            states[id] = nil
            return
        }
        state.status = .running(port: port)
        state.upstreamHost = upstream.host ?? upstream.absoluteString
        if state != states[id] {
            states[id] = state
        }
        var current = settings(for: id)
        if current.upstream != upstream.absoluteString {
            current.upstream = upstream.absoluteString
            settings[id] = current
        }
    }

    private func rememberUpstream(for id: Simulator.ID, request: MockRelaunchRequest) {
        var current = settings(for: id)
        if request.mode == .off {
            current.upstream = nil
        } else if let config = request.identity, let upstream = try? UpstreamResolver.upstream(environment: request.environment, config: config) {
            current.upstream = upstream.absoluteString
        }
        guard current != settings(for: id) else { return }
        settings[id] = current
    }

    private func relaunchRequest(for id: Simulator.ID, wanted: MockSimulatorSettings) -> MockRelaunchRequest {
        let project = session.selectedProject
        let identitySettings = identity.settings(for: id)
        return MockRelaunchRequest(
            udid: id,
            bundleID: project.identity?.bundleID ?? project.bundleID,
            identity: project.identity,
            deviceID: identitySettings.hasApplied ? identitySettings.appliedDeviceID : nil,
            environment: identity.storedEnvironment(for: id) ?? identitySettings.desiredEnvironment,
            mode: wanted.mode,
            set: wanted.setID.flatMap(sets.set(id:))
        )
    }

    private func pushRules(of setID: MockSet.ID) {
        let targets = states.filter { $0.value.mode == .mock && $0.value.setID == setID && $0.value.port != nil }.map(\.key)
        guard targets.isEmpty == false else { return }
        let rules = sets.set(id: setID)?.rules ?? []
        Task { [server] in
            for id in targets {
                await server.update(udid: id, rules: rules)
            }
        }
    }

    private func stopAll() {
        let running = Array(states.keys)
        states = [:]
        errors = [:]
        guard running.isEmpty == false else { return }
        Task { [server] in
            for id in running {
                await server.stop(udid: id)
            }
        }
    }

    private func title(for mode: MockMode, on name: String) -> String {
        switch mode {
        case .off: "Network mocks off on \(name)"
        case .passthrough: "Passthrough on \(name)"
        case .mock: "Network mocks on \(name)"
        }
    }

    private func detail(for state: MockServerState?) -> String {
        guard let state, let port = state.port else { return "App relaunched without the mock server" }
        return "Port \(port) → \(state.upstreamHost) · app relaunched"
    }

    private enum Keys {
        static let settings = "network.mock.settings"
    }
}
