import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct NotificationTargetCodecTests {
    @Test func everyTargetSurvivesTheUserInfoRoundTrip() {
        let targets: [ActivityTarget] = [.pullRequest(iid: 12), .reviewQueue, .worktree(path: "/repo/.worktrees/a b"), .build, .inbox, .utilities]

        for target in targets {
            let userInfo = NotificationTargetCodec.userInfo(for: target)
            #expect(NotificationTargetCodec.target(from: userInfo) == target)
        }
    }

    @Test func noTargetGivesEmptyUserInfoAndBackNil() {
        #expect(NotificationTargetCodec.userInfo(for: nil).isEmpty)
        #expect(NotificationTargetCodec.target(from: [:]) == nil)
        #expect(NotificationTargetCodec.target(from: ["target": "pullRequest", "iid": "x"]) == nil)
        #expect(NotificationTargetCodec.target(from: ["target": "worktree"]) == nil)
        #expect(NotificationTargetCodec.target(from: ["target": "unknown"]) == nil)
    }
}
