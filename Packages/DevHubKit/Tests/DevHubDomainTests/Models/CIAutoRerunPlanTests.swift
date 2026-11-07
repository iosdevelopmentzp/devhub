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

    @Test func aSavedPlanWithoutTheModeReadsAsFlakyOnly() throws {
        let data = Data(#"{"iid":7,"maxAttempts":5,"attempts":1,"handledWorkflowIDs":["w1"],"lastRerunAt":null}"#.utf8)

        let plan = try JSONDecoder().decode(CIAutoRerunPlan.self, from: data)

        #expect(plan.onlyFlaky)
        #expect(plan == CIAutoRerunPlan(iid: 7, maxAttempts: 5, attempts: 1, handledWorkflowIDs: ["w1"], lastRerunAt: nil))
    }

    @Test func theModeSurvivesASaveAndARead() throws {
        let plan = CIAutoRerunPlan(iid: 7, maxAttempts: 5, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil, onlyFlaky: false)

        #expect(try JSONDecoder().decode(CIAutoRerunPlan.self, from: JSONEncoder().encode(plan)) == plan)
    }
}
