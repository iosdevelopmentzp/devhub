import Testing
import DevHubUI
@testable import DevHubPresentation

@Suite struct StatusItemStateTests {
    private func state(building: Bool = false, failure: Bool = false, ciFailed: Bool = false, ciWaiting: Bool = false, awake: Bool = false) -> StatusItemState {
        StatusItemState.state(isBuilding: building, hasUnseenFailure: failure, isCIFailed: ciFailed, isCIWaiting: ciWaiting, isKeepingAwake: awake)
    }

    @Test func aRunningBuildWinsOverAFailure() {
        #expect(state(building: true, failure: true, ciFailed: true, ciWaiting: true, awake: true) == .building)
        #expect(state(failure: true, ciFailed: true, awake: true) == .failed)
        #expect(state() == .idle)
    }

    @Test func failedChecksWinOverAWaitingJobAndKeepAwake() {
        #expect(state(ciFailed: true, ciWaiting: true, awake: true) == .ciFailed)
        #expect(state(ciWaiting: true, awake: true) == .ciWaiting)
    }

    @Test func keepAwakeShowsACupWhenNothingElseIsGoingOn() {
        let state = state(awake: true)

        #expect(state == .awake)
        #expect(state.symbolName == "cup.and.saucer.fill")
        #expect(state.showsFailureDot == false)
    }

    @Test func theDotIsRedForFailuresAndOrangeForAWaitingJob() {
        #expect(StatusItemState.failed.dotTint == .red)
        #expect(StatusItemState.ciFailed.dotTint == .red)
        #expect(StatusItemState.ciWaiting.dotTint == .orange)
        #expect(StatusItemState.building.showsFailureDot == false)
        #expect(StatusItemState.building.symbolName == "hammer.circle.fill")
        #expect(StatusItemState.ciWaiting.symbolName == "hammer.fill")
    }
}
