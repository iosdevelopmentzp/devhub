import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct NetworkStoreTests {
    private let harness = StoreHarness()
    private let udid = SimulatorSample.booted.id

    private var store: NetworkStore {
        harness.network
    }

    private func receive(_ requests: [NetworkRequest]) {
        harness.simulators.groups = SimulatorSample.groups
        store.selectedUDID = udid
        for request in requests {
            harness.mockServer.receive(request, for: udid)
        }
    }

    // MARK: Persistence

    @Test func simulatorAndFilterAreRestored() {
        let saved = InMemoryKeyValueStore()
        saved.set(udid, forKey: "network.simulator")
        saved.set("slow", forKey: "network.filter")

        let store = StoreHarness(store: saved).network

        #expect(store.selectedUDID == udid)
        #expect(store.filter == .slow)
    }

    @Test func simulatorAndFilterAreWritten() {
        store.selectedUDID = udid
        store.filter = .failed

        #expect(harness.store.string(forKey: "network.simulator") == udid)
        #expect(harness.store.string(forKey: "network.filter") == "failed")
    }

    // MARK: Prepare

    @Test func preparePicksTheFirstBootedSimulator() {
        harness.simulators.groups = SimulatorSample.groups

        store.prepare(target: SimulatorSample.shutdown)

        #expect(store.selectedUDID == udid)
    }

    @Test func prepareReplacesASelectionThatIsNotBooted() {
        harness.simulators.groups = SimulatorSample.groups
        store.selectedUDID = SimulatorSample.shutdown.id

        store.prepare(target: nil)

        #expect(store.selectedUDID == udid)
    }

    @Test func prepareWithoutABootedSimulatorSelectsNothing() {
        harness.simulators.groups = SimulatorSample.shutdownOnly

        store.prepare(target: nil)

        #expect(store.selectedUDID == nil)
    }

    // MARK: List

    @Test func serverExchangesShowNewestFirst() {
        receive([NetworkRequestSample.ok, NetworkRequestSample.failed])

        #expect(store.shownRequests == [NetworkRequestSample.failed, NetworkRequestSample.ok])
    }

    @Test func anotherSimulatorShowsItsOwnExchanges() {
        receive([NetworkRequestSample.ok])

        store.select(SimulatorSample.shutdown.id)

        #expect(store.allRequests.isEmpty)
    }

    @Test func filtersFailedAndSlowRequests() {
        receive([NetworkRequestSample.ok, NetworkRequestSample.failed, NetworkRequestSample.slow])

        store.filter = .failed
        #expect(store.shownRequests == [NetworkRequestSample.failed])

        store.filter = .slow
        #expect(store.shownRequests == [NetworkRequestSample.slow])
    }

    @Test func searchMatchesMethodPathAndStatus() {
        receive([NetworkRequestSample.ok, NetworkRequestSample.failed, NetworkRequestSample.slow])

        harness.session.searchText = "422"
        #expect(store.shownRequests == [NetworkRequestSample.failed])

        harness.session.searchText = "leaderboard"
        #expect(store.shownRequests == [NetworkRequestSample.slow])

        harness.session.searchText = "post"
        #expect(store.shownRequests == [NetworkRequestSample.failed])
    }

    @Test func pauseFreezesTheListAndCountsTheNewOnes() {
        receive([NetworkRequestSample.ok])

        store.isPaused = true
        harness.mockServer.receive(NetworkRequestSample.failed, for: udid)

        #expect(store.allRequests == [NetworkRequestSample.ok])
        #expect(store.pendingCount == 1)
        store.isPaused = false
        #expect(store.allRequests.count == 2)
        #expect(store.pendingCount == 0)
    }

    @Test func toggleSelectionOpensAndClosesTheDetail() {
        receive([NetworkRequestSample.ok])

        store.toggleSelection(NetworkRequestSample.ok.id)
        #expect(store.selectedRequest == NetworkRequestSample.ok)

        store.toggleSelection(NetworkRequestSample.ok.id)
        #expect(store.selectedRequest == nil)
    }

    @Test func clearAlsoClearsTheServerExchanges() {
        receive([NetworkRequestSample.ok])
        store.toggleSelection(NetworkRequestSample.ok.id)

        store.clear()

        #expect(harness.mockServer.exchanges(for: udid).isEmpty)
        #expect(store.allRequests.isEmpty)
        #expect(store.selectedRequestID == nil)
    }

    // MARK: Events

    @Test func projectChangeClearsAndResumes() {
        receive([NetworkRequestSample.ok])
        store.isPaused = true

        harness.events.post(.projectChanged)

        #expect(store.allRequests.isEmpty)
        #expect(store.isPaused == false)
    }

    @Test func theSelectionIsDroppedWhenTheSimulatorIsGone() {
        receive([NetworkRequestSample.ok])
        harness.simulators.groups = SimulatorSample.shutdownOnly

        harness.events.post(.simulatorsChanged)

        #expect(store.selectedUDID == nil)
    }

    @Test func theSelectionStaysWhileTheSimulatorIsBooted() {
        receive([NetworkRequestSample.ok])

        harness.events.post(.simulatorsChanged)

        #expect(store.selectedUDID == udid)
    }
}
