import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIAutoRerunPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func workflow(_ status: CheckStatus) -> CIWorkflow {
        CIWorkflow(id: "w1", name: "build", status: status, runID: nil, jobs: [])
    }

    private func plan(attempts: Int = 0, handled: Set<String> = [], lastRerunAt: Date? = nil) -> CIAutoRerunPlan {
        CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: attempts, handledWorkflowIDs: handled, lastRerunAt: lastRerunAt)
    }

    @Test func aFailedWorkflowRunsAgainWhileAttemptsAreLeft() {
        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: plan(attempts: 2), failure: nil, now: now) == .rerun)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: plan(attempts: 3), failure: nil, now: now) == .exhausted)
    }

    @Test func theStateOfAWorkflowDecides() {
        #expect(CIAutoRerunPolicy.decision(for: workflow(.success), plan: plan(), failure: nil, now: now) == .succeeded)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.skipped), plan: plan(), failure: nil, now: now) == .succeeded)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.canceled), plan: plan(), failure: nil, now: now) == .cancelled)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.running), plan: plan(), failure: nil, now: now) == .wait)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.manual), plan: plan(), failure: nil, now: now) == .wait)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.other("unknown")), plan: plan(), failure: nil, now: now) == .wait)
    }

    @Test func aWorkflowThatRanAgainWaitsForItsNewRunThenIsIgnored() {
        let recent = plan(handled: ["w1"], lastRerunAt: now.addingTimeInterval(-60))
        let old = plan(handled: ["w1"], lastRerunAt: now.addingTimeInterval(-CIAutoRerunPolicy.newWorkflowGrace))
        let unknownTime = plan(handled: ["w1"], lastRerunAt: nil)

        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: recent, failure: nil, now: now) == .wait)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: old, failure: nil, now: now) == .handled)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: unknownTime, failure: nil, now: now) == .handled)
    }

    @Test func theOutcomeTakesTheStrongestDecision() {
        #expect(CIAutoRerunPolicy.outcome(of: [.succeeded, .rerun, .exhausted]) == .exhausted)
        #expect(CIAutoRerunPolicy.outcome(of: [.succeeded, .rerun, .cancelled]) == .cancelled)
        #expect(CIAutoRerunPolicy.outcome(of: [.succeeded, .wait, .rerun]) == .rerun)
        #expect(CIAutoRerunPolicy.outcome(of: [.succeeded, .wait]) == .wait)
    }

    @Test func successNeedsAtLeastOneWorkflowThatDidNotRunAgain() {
        #expect(CIAutoRerunPolicy.outcome(of: [.succeeded, .handled]) == .succeeded)
        #expect(CIAutoRerunPolicy.outcome(of: [.handled]) == .wait)
        #expect(CIAutoRerunPolicy.outcome(of: []) == .wait)
    }

    @Test func theChoicesHoldTheDefault() {
        #expect(CIAutoRerunPolicy.attemptChoices.contains(CIAutoRerunPolicy.defaultMaxAttempts))
    }

    @Test func withTheFlakyModeOnlyAFlakyFailureRunsAgain() {
        let flakyOnly = plan()
        let any = CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil, onlyFlaky: false)

        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: flakyOnly, failure: .allFlaky(testCount: 2), now: now) == .rerun)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: flakyOnly, failure: .realTests(job: "unit-tests", count: 1), now: now) == .stopped("unit-tests failed on a test that is not flaky"))
        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: flakyOnly, failure: .noTests(job: "build"), now: now) == .stopped("build failed without test results"))
        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: any, failure: .noTests(job: "build"), now: now) == .rerun)
        #expect(CIAutoRerunPolicy.decision(for: workflow(.failed), plan: plan(attempts: 3), failure: .noTests(job: "build"), now: now) == .exhausted)
    }

    @Test func aStopBeatsARerunButNotTheLastAttempt() {
        #expect(CIAutoRerunPolicy.outcome(of: [.rerun, .stopped("build failed without test results"), .cancelled]) == .stopped("build failed without test results"))
        #expect(CIAutoRerunPolicy.outcome(of: [.stopped("x"), .exhausted]) == .exhausted)
    }
}
