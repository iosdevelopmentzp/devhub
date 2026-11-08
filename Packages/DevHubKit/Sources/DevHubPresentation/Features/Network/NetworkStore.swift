import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class NetworkStore {
    var selectedRequestID: NetworkRequest.ID?
    var selectedUDID: Simulator.ID? {
        didSet {
            guard selectedUDID != oldValue else { return }
            store.set(selectedUDID, forKey: Keys.simulator)
        }
    }
    var filter: NetworkRequestFilter = .all {
        didSet {
            guard filter != oldValue else { return }
            store.set(filter.rawValue, forKey: Keys.filter)
        }
    }
    var isPaused = false {
        didSet {
            guard isPaused != oldValue else { return }
            frozenExchanges = isPaused ? liveExchanges : nil
        }
    }
    private(set) var sourceExchanges: [NetworkRequest] = []
    private(set) var sourceFailure: String?
    private var sourceRestarts = 0
    private var frozenExchanges: [NetworkRequest]?

    @ObservationIgnored private let followNetworkSource: FollowNetworkSourceUseCase
    @ObservationIgnored private let scriptEnvironment: SimulatorScriptEnvironment
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let mockTraffic: any MockTrafficLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(
        followNetworkSource: FollowNetworkSourceUseCase,
        scriptEnvironment: SimulatorScriptEnvironment,
        config: ConfigStore,
        session: ProjectSession,
        simulators: any SimulatorLookup,
        mockTraffic: any MockTrafficLookup,
        activity: ActivityLog,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.followNetworkSource = followNetworkSource
        self.scriptEnvironment = scriptEnvironment
        self.config = config
        self.session = session
        self.simulators = simulators
        self.mockTraffic = mockTraffic
        self.activity = activity
        self.store = store
        selectedUDID = store.string(forKey: Keys.simulator)
        filter = store.string(forKey: Keys.filter).flatMap(NetworkRequestFilter.init(rawValue:)) ?? .all
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                resetForProject()
            case .simulatorsChanged:
                dropSimulatorIfGone()
            default:
                break
            }
        }
    }

    var isIntercepting: Bool {
        selectedUDID.map(mockTraffic.isIntercepting) ?? false
    }

    var allRequests: [NetworkRequest] {
        (frozenExchanges ?? liveExchanges).reversed()
    }

    var shownRequests: [NetworkRequest] {
        allRequests.filter { request in
            filter.matches(request) && session.matchesSearch(request.method, request.path, request.statusCode.map(String.init) ?? "", request.host, request.graphQL?.title ?? "")
        }
    }

    var pendingCount: Int {
        guard let frozenExchanges else { return 0 }
        return max(0, liveExchanges.count - frozenExchanges.count)
    }

    var selectedRequest: NetworkRequest? {
        guard let selectedRequestID else { return nil }
        return allRequests.first { $0.id == selectedRequestID } ?? liveExchanges.first { $0.id == selectedRequestID }
    }

    var sourceScript: String? {
        guard session.hasProject, let script = config.config.network?.sourceScript?.trimmed, script.isEmpty == false else { return nil }
        return script
    }

    var sourceKey: String {
        [selectedUDID ?? "", sourceScript ?? "", session.selectedProject.path, String(sourceRestarts)].joined(separator: "|")
    }

    private var liveExchanges: [NetworkRequest] {
        guard let selectedUDID else { return [] }
        return NetworkTrafficPolicy.merge(
            mockServer: mockTraffic.exchanges(for: selectedUDID),
            sourceScript: sourceExchanges,
            isIntercepting: mockTraffic.isIntercepting(selectedUDID)
        )
    }

    func followSource() async {
        sourceExchanges = []
        sourceFailure = nil
        guard let script = sourceScript, let udid = selectedUDID, let simulator = simulators.simulator(id: udid) else { return }
        let request = NetworkSourceRequest(
            script: script,
            layers: config.resolved.layers,
            projectPath: session.selectedProject.path,
            environment: await scriptEnvironment.environment(for: simulator)
        )
        guard Task.isCancelled == false else { return }
        do {
            for try await event in followNetworkSource.execute(request) {
                guard Task.isCancelled == false else { return }
                switch event {
                case let .request(request):
                    sourceExchanges = NetworkTrafficPolicy.upsert(request, into: sourceExchanges)
                case let .error(message):
                    sourceFailure = message
                case .output, .exited:
                    break
                }
            }
        } catch {
            guard Task.isCancelled == false else { return }
            sourceFailure = error.localizedDescription
            activity.log("The network source script stopped", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func restartSource() {
        sourceRestarts += 1
    }

    func prepare(target: Simulator?) {
        let all = simulators.all
        if let selectedUDID, all.isEmpty == false, all.contains(where: { $0.id == selectedUDID && $0.state == .booted && $0.isPhysical == false }) == false {
            self.selectedUDID = nil
        }
        if selectedUDID == nil {
            selectedUDID = LogTargetPolicy.defaultSimulator(target: target, simulators: all)?.id
        }
    }

    func select(_ udid: Simulator.ID?) {
        selectedUDID = udid
        selectedRequestID = nil
        frozenExchanges = isPaused ? liveExchanges : nil
    }

    func clear() {
        if let selectedUDID {
            mockTraffic.clearExchanges(for: selectedUDID)
        }
        sourceExchanges = []
        selectedRequestID = nil
        frozenExchanges = isPaused ? [] : nil
    }

    func toggleSelection(_ id: NetworkRequest.ID) {
        selectedRequestID = selectedRequestID == id ? nil : id
    }

    private func resetForProject() {
        clear()
        isPaused = false
    }

    private func dropSimulatorIfGone() {
        guard let udid = selectedUDID, simulators.all.isEmpty == false, simulators.simulator(id: udid)?.state != .booted else { return }
        select(nil)
    }

    private enum Keys {
        static let simulator = "network.simulator"
        static let filter = "network.filter"
    }
}
