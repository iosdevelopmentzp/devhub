import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIAutoRerunPlanTests {
    @Test func theAttemptsLeftNeverGoBelowZero() {
        #expect(CIAutoRerunPlan(iid: 7, maxAttempts: 10, attempts: 3, handledWorkflowIDs: [], lastRerunAt: nil).attemptsLeft == 7)
        #expect(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 5, handledWorkflowIDs: [], lastRerunAt: nil).attemptsLeft == 0)
    }

    @Test func itSurvivesASaveAndARead() throws {
        let plan = CIAutoRerunPlan(iid: 7, maxAttempts: 5, attempts: 1, handledWorkflowIDs: ["w1"], lastRerunAt: Date(timeIntervalSince1970: 1_800_000_000))

        let data = try JSONEncoder().encode(plan)

        #expect(try JSONDecoder().decode(CIAutoRerunPlan.self, from: data) == plan)
    }
}
