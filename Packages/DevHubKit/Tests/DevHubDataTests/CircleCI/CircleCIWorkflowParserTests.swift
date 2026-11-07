import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIWorkflowParserTests {
    @Test func aFinishedWorkflowListsItsJobsWithTheirStates() throws {
        let workflow = try CircleCIWorkflowParser.workflow(from: CircleCIFixture.workflow, id: "fallback")

        #expect(workflow.id == CircleCIFixture.workflowID)
        #expect(workflow.name == "build-and-test")
        #expect(workflow.status == .failed)
        #expect(workflow.runID == CircleCIFixture.runID)
        #expect(workflow.jobs.map(\.id) == ["job-build", "job-unit-tests", "job-approve-release", "job-deploy"])
        #expect(workflow.jobs.map(\.name) == ["build", "unit-tests", "approve-release", "deploy"])
        #expect(workflow.jobs.map(\.status) == [.success, .failed, .manual, .pending])
        #expect(workflow.jobs.map(\.isApproval) == [false, false, true, false])
    }

    @Test func aRunningWorkflowTakesTheStateFromThePhase() throws {
        let workflow = try CircleCIWorkflowParser.workflow(from: CircleCIFixture.runningWorkflow, id: "fallback")

        #expect(workflow.status == .running)
        #expect(workflow.jobs.isEmpty)
    }

    @Test func aMissingIDFallsBackToTheRequestedOne() throws {
        let workflow = try CircleCIWorkflowParser.workflow(from: Data(#"{"name":"x","phase":"created"}"#.utf8), id: "requested")

        #expect(workflow.id == "requested")
        #expect(workflow.status == .pending)
        #expect(workflow.runID == nil)
    }

    @Test func brokenJSONIsACommandError() {
        #expect(throws: CIError.self) {
            try CircleCIWorkflowParser.workflow(from: Data("not json".utf8), id: "x")
        }
    }

    @Test func theV3PhasesGiveTheRunningStateAndTheApprovalOnHold() throws {
        let workflow = try CircleCIWorkflowParser.workflow(from: CircleCIFixture.workflowV3, id: "x")

        #expect(workflow.status == .running)
        #expect(workflow.jobs.map(\.status) == [.success, .failed, .manual, .pending])
        #expect(workflow.jobs.map(\.isApproval) == [false, false, true, false])
    }
}
