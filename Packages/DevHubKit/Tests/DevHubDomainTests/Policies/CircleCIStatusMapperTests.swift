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

    @Test func theV3PhasesDecideBeforeTheOutcome() {
        #expect(CircleCIStatusMapper.status(phase: "created", outcome: nil, currentOutcome: nil) == .pending)
        #expect(CircleCIStatusMapper.status(phase: "queued", outcome: "", currentOutcome: "unknown") == .pending)
        #expect(CircleCIStatusMapper.status(phase: "started", outcome: nil, currentOutcome: "failed") == .running)
        #expect(CircleCIStatusMapper.status(phase: "ended", outcome: "succeeded", currentOutcome: nil) == .success)
        #expect(CircleCIStatusMapper.status(phase: "ended", outcome: "", currentOutcome: "failed") == .failed)
        #expect(CircleCIStatusMapper.status(phase: "ended", outcome: "not_run", currentOutcome: nil) == .skipped)
        #expect(CircleCIStatusMapper.status(phase: "ended", outcome: "canceled", currentOutcome: nil) == .canceled)
        #expect(CircleCIStatusMapper.status(phase: "ended", outcome: "infrastructure_fail", currentOutcome: nil) == .failed)
        #expect(CircleCIStatusMapper.status(phase: "ended", outcome: nil, currentOutcome: nil) == .other("unknown"))
    }

    @Test func anApprovalJobThatStartedWaitsForTheApproval() {
        #expect(CircleCIStatusMapper.jobStatus(phase: "started", outcome: nil, currentOutcome: nil, isApproval: true) == .manual)
        #expect(CircleCIStatusMapper.jobStatus(phase: "ended", outcome: "succeeded", currentOutcome: nil, isApproval: true) == .success)
        #expect(CircleCIStatusMapper.jobStatus(phase: "started", outcome: nil, currentOutcome: nil, isApproval: false) == .running)
    }
}
