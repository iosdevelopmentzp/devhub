import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct TestOutputParserTests {
    @Test func xcTestCaseLines() {
        #expect(TestOutputParser.parse("Test Case '-[ExampleAppTests.LoginTests testLogin]' passed (0.123 seconds).") == .testFinished(TestCaseResult(suite: "LoginTests", name: "testLogin", status: .passed, duration: 0.123)))
        #expect(TestOutputParser.parse("Test Case '-[ExampleAppTests.LoginTests testLogin]' failed (0.5 seconds).") == .testFinished(TestCaseResult(suite: "LoginTests", name: "testLogin", status: .failed, duration: 0.5)))
        #expect(TestOutputParser.parse("Test Case '-[ExampleAppTests.LoginTests testWatch]' skipped (0.001 seconds).") == .testFinished(TestCaseResult(suite: "LoginTests", name: "testWatch", status: .skipped, duration: 0.001)))
        #expect(TestOutputParser.parse("Test Case 'LoginTests.testLogin' passed (0.2 seconds)") == .testFinished(TestCaseResult(suite: "LoginTests", name: "testLogin", status: .passed, duration: 0.2)))
    }

    @Test func xcTestFailureLine() {
        let line = "/Users/alex/app/Tests/LoginTests.swift:42: error: -[ExampleAppTests.LoginTests testLogin] : XCTAssertEqual failed: (\"1\") is not equal to (\"2\")"

        #expect(TestOutputParser.parse(line) == .failure(TestFailure(
            test: "LoginTests.testLogin",
            file: "LoginTests.swift",
            path: "/Users/alex/app/Tests/LoginTests.swift",
            line: 42,
            message: "XCTAssertEqual failed: (\"1\") is not equal to (\"2\")"
        )))
    }

    @Test(arguments: [
        "✔ Test \"login works\" passed after 0.001 seconds.",
        "􀁣 Test \"login works\" passed after 0.001 seconds.",
        "  ✔ Test \"login works\" passed after 0.001 seconds.",
    ])
    func swiftTestingPassedLineWithAnySymbol(line: String) {
        #expect(TestOutputParser.parse(line) == .testFinished(TestCaseResult(suite: nil, name: "login works", status: .passed, duration: 0.001)))
    }

    @Test func swiftTestingFailedSkippedAndFunctionNames() {
        #expect(TestOutputParser.parse("✘ Test \"login works\" failed after 0.2 seconds with 1 issue.") == .testFinished(TestCaseResult(suite: nil, name: "login works", status: .failed, duration: 0.2)))
        #expect(TestOutputParser.parse("✔ Test feedOrder() passed after 0.03 seconds.") == .testFinished(TestCaseResult(suite: nil, name: "feedOrder()", status: .passed, duration: 0.03)))
        #expect(TestOutputParser.parse("↷ Test \"watch only\" skipped.") == .testFinished(TestCaseResult(suite: nil, name: "watch only", status: .skipped, duration: nil)))
        #expect(TestOutputParser.parse("⚠ Test \"flaky\" passed after 0.1 seconds with 1 known issue.") == .testFinished(TestCaseResult(suite: nil, name: "flaky", status: .passed, duration: 0.1)))
    }

    @Test func swiftTestingIssueLine() {
        let line = "✘ Test \"login works\" recorded an issue at LoginTests.swift:42:9: Expectation failed: (a → 1) == (b → 2)"

        #expect(TestOutputParser.parse(line) == .failure(TestFailure(test: "login works", file: "LoginTests.swift", path: nil, line: 42, message: "Expectation failed: (a → 1) == (b → 2)")))
    }

    @Test(arguments: [
        "Test Suite 'All tests' started at 2026-10-31 10:00:00.000.",
        "◇ Test run started.",
        "Testing started on iPhone 17",
    ])
    func runStartedLines(line: String) {
        #expect(TestOutputParser.parse(line) == .runStarted)
    }

    @Test(arguments: [
        "",
        "Test Case '-[ExampleAppTests.LoginTests testLogin]' started.",
        "Test Suite 'LoginTests' passed at 2026-10-31 10:00:01.000.",
        "✔ Test run with 12 tests in 3 suites passed after 0.5 seconds.",
        "✔ Suite \"LoginTests\" passed after 0.2 seconds.",
        "◇ Suite \"LoginTests\" started.",
        "\tExecuted 12 tests, with 1 failure (0 unexpected) in 0.5 (0.6) seconds",
        "/Users/alex/app/Sources/Login.swift:10:5: error: cannot find 'x' in scope",
        "** TEST FAILED **",
        "⚠ Test \"flaky\" recorded a known issue at LoginTests.swift:12:5: Expectation failed",
    ])
    func otherLinesAreIgnored(line: String) {
        #expect(TestOutputParser.parse(line) == nil)
    }
}
