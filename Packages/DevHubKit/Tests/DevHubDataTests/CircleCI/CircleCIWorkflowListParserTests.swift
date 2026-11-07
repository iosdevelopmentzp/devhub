import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIWorkflowListParserTests {
    @Test func theWorkflowsOfARunKeepTheRunID() throws {
        let workflows = try CircleCIWorkflowListParser.workflows(from: CircleCIFixture.workflowList, runID: "run-1")

        #expect(workflows.map(\.name) == ["build-and-test", "nightly"])
        #expect(workflows.map(\.status) == [.failed, .running])
        #expect(workflows.map(\.runID) == [CircleCIFixture.runID, "run-1"])
        #expect(workflows.allSatisfy { $0.jobs.isEmpty })
    }

    @Test func aPageObjectIsReadToo() throws {
        let workflows = try CircleCIWorkflowListParser.workflows(from: Data(#"{"items":[{"id":"w9","name":"x","phase":"ended","outcome":"succeeded"}]}"#.utf8), runID: "run-1")

        #expect(workflows.map(\.id) == ["w9"])
        #expect(workflows.first?.status == .success)
    }
}
