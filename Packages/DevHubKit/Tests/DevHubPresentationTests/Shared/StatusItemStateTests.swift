import Testing
@testable import DevHubPresentation

@Suite struct StatusItemStateTests {
    @Test func aRunningBuildWinsOverAFailure() {
        #expect(StatusItemState.state(isBuilding: true, hasUnseenFailure: true) == .building)
        #expect(StatusItemState.state(isBuilding: false, hasUnseenFailure: true) == .failed)
        #expect(StatusItemState.state(isBuilding: false, hasUnseenFailure: false) == .idle)
    }

    @Test func onlyAFailureShowsTheRedDot() {
        #expect(StatusItemState.failed.showsFailureDot)
        #expect(StatusItemState.building.showsFailureDot == false)
        #expect(StatusItemState.building.symbolName == "hammer.circle.fill")
    }
}
