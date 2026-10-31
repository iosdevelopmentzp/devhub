import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCITestResultParserTests {
    @Test func jsonLinesBecomeResults() throws {
        let results = try CircleCITestResultParser.results(from: CircleCIFixture.testResults)

        #expect(results == [
            CITestResult(className: "LoginViewModelTests", name: "testRetryAfterTimeout", result: "failure", runTime: 2.4, message: "XCTAssertEqual failed"),
            CITestResult(className: "ProfileBadgeTests", name: "testBadgeCount", result: "failure", runTime: 0.1, message: nil),
        ])
    }

    @Test func anArrayIsReadAndNamelessEntriesAreDropped() throws {
        let results = try CircleCITestResultParser.results(from: CircleCIFixture.testResultsArray)

        #expect(results.map(\.name) == ["testRetryAfterTimeout"])
    }

    @Test func emptyOutputIsAnEmptyList() throws {
        #expect(try CircleCITestResultParser.results(from: Data()).isEmpty)
        #expect(try CircleCITestResultParser.results(from: Data("\n".utf8)).isEmpty)
    }

    @Test func aBrokenLineIsACommandError() {
        #expect(throws: CIError.self) {
            try CircleCITestResultParser.results(from: Data("{\"name\":\"a\"}\nnope\n".utf8))
        }
    }
}
