import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class SimulatorStatusStore {
    private(set) var statuses: [Simulator.ID: SimulatorStatus] = [:]
    private(set) var reports: [Simulator.ID: AppStateReport] = [:]

    @ObservationIgnored private let readStatus: ReadSimulatorStatusUseCase
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let build: any BuildLookup
    @ObservationIgnored private let codeHosts: any CodeHostLookup
    @ObservationIgnored private let launcher: any AppLaunchRepository
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let settleDelay: Duration
    @ObservationIgnored private var tasks: [Simulator.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(readStatus: ReadSimulatorStatusUseCase, config: ConfigStore, session: ProjectSession, simulators: any SimulatorLookup, build: any BuildLookup, codeHosts: any CodeHostLookup, launcher: any AppLaunchRepository, events: AppEvents, settleDelay: Duration) {
        self.readStatus = readStatus
        self.config = config
        self.session = session
        self.simulators = simulators
        self.build = build
        self.codeHosts = codeHosts
        self.launcher = launcher
        self.events = events
        self.settleDelay = settleDelay
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .configChanged, .projectChanged, .refreshRequested(.simulators):
                reloadAll()
            case .simulatorsChanged:
                loadMissing()
            case let .appLaunched(id, _), let .buildFinished(id, _):
                guard let simulator = simulators.simulator(id: id) else { return }
                read(simulator, after: settleDelay)
            default:
                break
            }
        }
    }

    func loadMissing() {
        for simulator in wanted where statuses[simulator.id] == nil && tasks[simulator.id] == nil {
            read(simulator)
        }
    }

    func reloadAll() {
        tasks.values.forEach { $0.cancel() }
        tasks = [:]
        statuses = [:]
        for id in reports.keys {
            events.post(.appStateReported(simulatorID: id, report: nil))
        }
        reports = [:]
        loadMissing()
    }

    private var script: String? {
        guard session.hasProject else { return nil }
        return config.config.simulators?.statusScript
    }

    private var wanted: [Simulator] {
        guard script != nil else { return [] }
        let targetID = build.target?.id
        return simulators.all.filter { $0.state == .booted || $0.isFavorite || $0.id == targetID }
    }

    private func read(_ simulator: Simulator, after delay: Duration = .zero) {
        guard let script else { return }
        tasks[simulator.id]?.cancel()
        let layers = config.resolved.layers
        let projectPath = session.selectedProject.path
        tasks[simulator.id] = Task { [weak self] in
            guard let self else { return }
            let request = SimulatorStatusRequest(
                script: script,
                layers: layers,
                projectPath: projectPath,
                environment: await environment(for: simulator)
            )
            await load(simulator.id, request: request, after: delay)
        }
    }

    private func load(_ id: Simulator.ID, request: SimulatorStatusRequest, after delay: Duration) async {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        guard Task.isCancelled == false else { return }
        let reading = await reading(for: request)
        guard Task.isCancelled == false else { return }
        if statuses[id] != reading.status {
            statuses[id] = reading.status
        }
        if reports[id] != reading.state {
            reports[id] = reading.state
            events.post(.appStateReported(simulatorID: id, report: reading.state))
        }
        tasks[id] = nil
    }

    private func reading(for request: SimulatorStatusRequest) async -> (status: SimulatorStatus?, state: AppStateReport?) {
        do {
            let reading = try await readStatus.execute(request)
            return (reading.line.map { SimulatorStatus(text: $0, isFailure: false) }, reading.state)
        } catch {
            return (SimulatorStatus(text: error.localizedDescription, isFailure: true), nil)
        }
    }

    private func environment(for simulator: Simulator) async -> [String: String] {
        let project = session.selectedProject
        let path = ProjectPath(project.path).expanded
        let effective = config.effective(detectedSchemes: build.schemeOptions, detectedBaseBranch: nil)
        let containers = await launcher.containers(udid: simulator.id, bundleID: effective.bundleID ?? "")
        return ActionContextPolicy.make(ActionContextInputs(
            projectPath: path,
            projectName: project.name,
            checkoutPath: path,
            branch: "",
            effective: effective,
            simulatorUDID: simulator.id,
            simulatorName: simulator.name,
            appPath: build.lastBuiltAppPath() ?? "",
            configDir: "",
            item: ActionItemContext(simulatorUDID: simulator.id, simulatorName: simulator.name, rowID: simulator.id),
            inputs: [:],
            version: "",
            profileID: build.profile(for: simulator.id)?.id ?? "",
            hostKind: codeHosts.kind,
            containers: containers,
            simulatorState: simulator.state
        )).environment
    }
}
