import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIJobStepsParserTests {
    @Test func theStepsOfTheLastExecutionWithTheirDurations() throws {
        let steps = try CircleCIJobStepsParser.steps(from: CircleCIFixture.jobV3)

        #expect(steps.map(\.name) == ["Spin up environment", "Checkout code", "Run tests", "Upload test results"])
        #expect(steps.map(\.index) == [0, 1, 2, 3])
        #expect(steps.map(\.status) == [.success, .success, .failed, .running])
        #expect(steps.map(\.duration) == [2, 8, 452, nil])
        #expect(steps.map(\.exitCode) == [0, 0, 65, nil])
        #expect(steps.filter(\.isFailed).map(\.name) == ["Run tests"])
    }

    @Test func aJobWithoutExecutionsHasNoSteps() throws {
        #expect(try CircleCIJobStepsParser.steps(from: Data(#"{"id":"j1","executions":[]}"#.utf8)).isEmpty)
        #expect(try CircleCIJobStepsParser.steps(from: Data(#"{"id":"j1"}"#.utf8)).isEmpty)
    }

    @Test func brokenJSONIsACommandError() {
        #expect(throws: CIError.self) {
            try CircleCIJobStepsParser.steps(from: Data("[".utf8))
        }
    }
}
