import Testing
@testable import DevHubDomain

@Suite struct CircleCIStatusMapperTests {
    @Test(arguments: [
        ("success", CheckStatus.success), ("succeeded", .success), ("failed", .failed), ("failing", .failed), ("error", .failed),
        ("infrastructure_fail", .failed), ("timedout", .failed), ("running", .running), ("on_hold", .manual), ("needs_approval", .manual),
        ("canceled", .canceled), ("cancelled", .canceled), ("not_run", .skipped), ("skipped", .skipped), ("queued", .pending),
        ("created", .pending), ("blocked", .pending), ("pending", .pending), ("Success", .success), ("", .other("unknown")), ("weird", .other("weird")),
    ])
    func everyKnownWordMapsToACheckStatus(word: String, expected: CheckStatus) {
        #expect(CircleCIStatusMapper.status(word) == expected)
    }

    @Test func theOutcomeWinsWhenItIsKnown() {
        #expect(CircleCIStatusMapper.status(phase: "finished", outcome: "failed") == .failed)
        #expect(CircleCIStatusMapper.status(phase: "running", outcome: "unknown") == .running)
        #expect(CircleCIStatusMapper.status(phase: "on_hold", outcome: nil) == .manual)
        #expect(CircleCIStatusMapper.status(phase: "blocked", outcome: "") == .pending)
        #expect(CircleCIStatusMapper.status(phase: nil, outcome: nil) == .other("unknown"))
    }
}
