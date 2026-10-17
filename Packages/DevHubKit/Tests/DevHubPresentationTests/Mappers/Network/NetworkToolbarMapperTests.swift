import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct NetworkToolbarMapperTests {
    @Test func listsOnlyBootedSimulatorsWithRuntime() {
        let model = map(simulators: [SimulatorFixture.iPhone, SimulatorFixture.iPad], isPaused: false, pending: 0, shown: 0, total: 0)

        #expect(model.simulators == [NetworkToolbarModel.SimulatorOption(id: SimulatorFixture.iPhone.id, title: "iPhone 16 Pro · iOS 18.2")])
        #expect(model.filters.map(\.title) == ["All", "Failed", "Slow"])
        #expect(model.filters.map(\.id) == [.all, .failed, .slow])
    }

    @Test func countShowsTheFilteredPart() {
        #expect(map(simulators: [], isPaused: false, pending: 0, shown: 4, total: 4).countText == "4 requests")
        #expect(map(simulators: [], isPaused: false, pending: 0, shown: 1, total: 4).countText == "1 of 4 requests")
    }

    @Test func pauseTitleShowsWaitingRequestsOnlyWhilePaused() {
        #expect(map(simulators: [], isPaused: false, pending: 3, shown: 0, total: 0).pauseTitle == "Pause")
        #expect(map(simulators: [], isPaused: true, pending: 0, shown: 0, total: 0).pauseTitle == "Pause")
        #expect(map(simulators: [], isPaused: true, pending: 3, shown: 0, total: 0).pauseTitle == "Paused · 3 new")
    }

    @Test func clearNeedsSomethingToClear() {
        #expect(map(simulators: [], isPaused: false, pending: 0, shown: 0, total: 0).canClear == false)
        #expect(map(simulators: [], isPaused: true, pending: 1, shown: 0, total: 0).canClear)
        #expect(map(simulators: [], isPaused: false, pending: 0, shown: 0, total: 2).canClear)
    }

    private func map(simulators: [Simulator], isPaused: Bool, pending: Int, shown: Int, total: Int) -> NetworkToolbarModel {
        NetworkToolbarMapper.model(
            simulators: simulators,
            runtime: { $0 == SimulatorFixture.iPhone.id ? "iOS 18.2" : nil },
                        isPaused: isPaused,
            pendingCount: pending,
            shownCount: shown,
            totalCount: total
        )
    }
}
