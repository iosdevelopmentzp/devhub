import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIWorkflowDetailsParserTests {
    @Test func theWorkflowAndItsJobsComeFromTheTwoAnswers() throws {
        let details = try CircleCIWorkflowDetailsParser.details(workflow: CircleCIFixture.workflowV2, jobs: CircleCIFixture.workflowJobsV2, id: "fallback")

        #expect(details.id == CircleCIFixture.workflowID)
        #expect(details.pipelineNumber == 42)
        #expect(details.projectSlug == "gh/example/app")
        #expect(details.createdAt != nil)
        #expect(details.stoppedAt != nil)
        #expect(details.jobs.map(\.id) == ["job-build", "job-unit-tests", "job-approve-release"])
        #expect(details.jobs.map(\.number) == [101, 102, nil])
        #expect(details.job("job-unit-tests")?.duration(now: .now) == 505)
        #expect(details.job("job-approve-release")?.approvalRequestID == "44444444-5555-6666-7777-888888888888")
        #expect(details.job("job-approve-release")?.startedAt == nil)
    }

    @Test func aPlainJobListAndAMissingIDAreRead() throws {
        let details = try CircleCIWorkflowDetailsParser.details(workflow: Data("{}".utf8), jobs: Data(#"[{"id":"j1","job_number":7}]"#.utf8), id: "w1")

        #expect(details.id == "w1")
        #expect(details.pipelineNumber == nil)
        #expect(details.jobs.map(\.number) == [7])
    }

    @Test func brokenJSONIsACommandError() {
        #expect(throws: CIError.self) {
            try CircleCIWorkflowDetailsParser.details(workflow: Data("{".utf8), jobs: Data("[]".utf8), id: "w1")
        }
    }
}
