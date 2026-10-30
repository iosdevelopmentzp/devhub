import Foundation
import DevHubDomain

extension MockData {
    package static let testResults: [TestCaseResult] = [
        TestCaseResult(suite: "LoginTests", name: "testLoginWithValidCredentials", status: .passed, duration: 0.12),
        TestCaseResult(suite: "LoginTests", name: "testLoginWithWrongPassword", status: .failed, duration: 0.08),
        TestCaseResult(suite: "LoginTests", name: "testBiometricsOnWatch", status: .skipped, duration: nil),
        TestCaseResult(suite: nil, name: "feed shows the newest post first", status: .passed, duration: 0.03),
        TestCaseResult(suite: nil, name: "feed hides blocked authors", status: .passed, duration: 0.02)
    ]

    package static let testFailures: [TestFailure] = [
        TestFailure(
            test: "LoginTests.testLoginWithWrongPassword",
            file: "LoginTests.swift",
            path: "/Users/dev/Projects/ExampleApp/Tests/LoginTests.swift",
            line: 42,
            message: "XCTAssertEqual failed: (\"locked\") is not equal to (\"wrongPassword\")"
        )
    ]
}
