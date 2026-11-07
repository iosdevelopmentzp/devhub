import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct XcresultParserTests {
    @Test func flattensTheTreeIntoTestCases() throws {
        let cases = try XcresultParser.cases(from: XcresultFixture.tests)

        #expect(cases.map(\.identifier) == ["LoginTests/testLoginWorks()", "LoginTests/testSkipped()", "LoginTests/testSlow()", "LoginTests/testWrongPassword()", "FeedUITests/testScroll()", "FeedUITests/testExpected()"])
        #expect(cases.map(\.status) == [.passed, .skipped, .passed, .failed, .failed, .passed])
        #expect(cases[0].target == "ExampleAppTests")
        #expect(cases[0].suite == "LoginTests")
        #expect(cases[2].duration == 0.61)
        #expect(cases[1].failureMessage == nil)
    }

    @Test func aFailureMessageGivesTheFileAndLine() throws {
        let failed = try XcresultParser.cases(from: XcresultFixture.tests)[3]

        #expect(failed.file == "LoginTests.swift")
        #expect(failed.line == 14)
        #expect(failed.failureMessage == #"XCTAssertEqual failed: ("locked") is not equal to ("wrongPassword")"#)
        #expect(failed.onlyTestingID == "ExampleAppTests/LoginTests/testWrongPassword")
    }

    @Test func aRepetitionAndASourceReferenceAreRead() throws {
        let failed = try XcresultParser.cases(from: XcresultFixture.tests)[4]

        #expect(failed.target == "ExampleAppUITests")
        #expect(failed.failureMessage == "Element not found")
        #expect(failed.file == "FeedUITests.swift")
        #expect(failed.line == 30)
    }

    @Test func aBrokenAnswerThrows() {
        #expect(throws: TestRunError.self) {
            try XcresultParser.cases(from: Data("not json".utf8))
        }
    }
}
