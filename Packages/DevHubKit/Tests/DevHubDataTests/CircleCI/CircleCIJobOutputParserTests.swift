import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIJobOutputParserTests {
    @Test func theFailedStepComesFirstWithItsExitCodeAndWithoutColours() throws {
        let log = try CircleCIJobOutputParser.log(from: CircleCIFixture.jobOutput)

        #expect(log == "== Run tests (exit 65)\nTest Case failed\nExecuted 2 tests\n\n== Spin up environment\nBuild-agent version 1.0.0")
    }

    @Test func aStepWithoutOutputKeepsOnlyItsHeader() throws {
        let log = try CircleCIJobOutputParser.log(from: Data(#"[{"num":3,"name":"Save cache","exit_code":0,"output":""},{"num":4,"exit_code":1}]"#.utf8))

        #expect(log == "== Step 4 (exit 1)\n\n== Save cache")
    }

    @Test func brokenJSONIsACommandError() {
        #expect(throws: CIError.self) {
            try CircleCIJobOutputParser.log(from: Data("{".utf8))
        }
    }
}
