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
    private var frozenExchanges: [NetworkRequest]?

    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let mockTraffic: any MockTrafficLookup
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(
        session: ProjectSession,
        simulators: any SimulatorLookup,
        mockTraffic: any MockTrafficLookup,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.session = session
        self.simulators = simulators
        self.mockTraffic = mockTraffic
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

    private var liveExchanges: [NetworkRequest] {
        selectedUDID.map(mockTraffic.exchanges(for:)) ?? []
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
