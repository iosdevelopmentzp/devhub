import Testing
@testable import DevHubPresentation

@Suite struct StatusItemStateTests {
    @Test func aRunningBuildWinsOverAFailure() {
        #expect(StatusItemState.state(isBuilding: true, hasUnseenFailure: true, isKeepingAwake: true) == .building)
        #expect(StatusItemState.state(isBuilding: false, hasUnseenFailure: true, isKeepingAwake: true) == .failed)
        #expect(StatusItemState.state(isBuilding: false, hasUnseenFailure: false, isKeepingAwake: false) == .idle)
    }

    @Test func keepAwakeShowsACupWhenNothingElseIsGoingOn() {
        let state = StatusItemState.state(isBuilding: false, hasUnseenFailure: false, isKeepingAwake: true)

        #expect(state == .awake)
        #expect(state.symbolName == "cup.and.saucer.fill")
        #expect(state.showsFailureDot == false)
    }

    @Test func onlyAFailureShowsTheRedDot() {
        #expect(StatusItemState.failed.showsFailureDot)
        #expect(StatusItemState.building.showsFailureDot == false)
        #expect(StatusItemState.building.symbolName == "hammer.circle.fill")
    }
}
