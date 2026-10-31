import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIFlakyTestParserTests {
    @Test func theInsightsAnswerBecomesFlakyTests() throws {
        let tests = try CircleCIFlakyTestParser.tests(from: CircleCIFixture.flakyTests)

        #expect(tests == [
            CIFlakyTest(className: "LoginViewModelTests", name: "testRetryAfterTimeout", jobName: "unit-tests", workflowName: "build-and-test", timesFlaked: 7),
        ])
    }

    @Test func anAnswerWithoutTheListIsEmpty() throws {
        #expect(try CircleCIFlakyTestParser.tests(from: Data(#"{"total-flaky-tests":0}"#.utf8)).isEmpty)
    }

    @Test func brokenJSONIsACommandError() {
        #expect(throws: CIError.self) {
            try CircleCIFlakyTestParser.tests(from: Data("[".utf8))
        }
    }
}
