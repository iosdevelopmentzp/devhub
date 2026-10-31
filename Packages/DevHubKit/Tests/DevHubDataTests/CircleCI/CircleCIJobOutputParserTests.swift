import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIJobOutputParserTests {
    @Test func stepsAreJoinedWithAHeaderAndTheExitCodeOfAFailedStep() throws {
        let log = try CircleCIJobOutputParser.log(from: CircleCIFixture.jobOutput)

        #expect(log == "== Spin up environment\nBuild-agent version 1.0.0\n\n== Run tests (exit 65)\nTest Case failed\nExecuted 2 tests")
    }

    @Test func aStepWithoutOutputKeepsOnlyItsHeader() throws {
        let log = try CircleCIJobOutputParser.log(from: Data(#"[{"num":3,"name":"Save cache","exit_code":0,"output":""},{"num":4,"exit_code":1}]"#.utf8))

        #expect(log == "== Save cache\n\n== Step 4 (exit 1)")
    }

    @Test func brokenJSONIsACommandError() {
        #expect(throws: CIError.self) {
            try CircleCIJobOutputParser.log(from: Data("{".utf8))
        }
    }
}
