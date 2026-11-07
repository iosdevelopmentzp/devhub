import Foundation
import Testing
@testable import DevHubDomain

@Suite struct TestResultsPolicyTests {
    private func item(_ name: String, _ status: TestCaseResult.Status, duration: TimeInterval?, target: String? = "AppTests") -> TestResultCase {
        TestResultCase(identifier: "Suite/\(name)()", target: target, suite: "Suite", name: "\(name)()", status: status, duration: duration, failureMessage: status == .failed ? "boom" : nil)
    }

    @Test func slowestSortsByDurationAndKeepsTen() {
        let cases = (1...12).map { item("t\($0)", .passed, duration: Double($0)) } + [item("none", .passed, duration: nil)]

        let slowest = TestResultsPolicy.slowest(cases)

        #expect(slowest.count == 10)
        #expect(slowest.first?.name == "t12()")
        #expect(slowest.last?.name == "t3()")
    }

    @Test func failuresAndOnlyTestsComeFromTheFailedCases() {
        let cases = [item("a", .passed, duration: 1), item("b", .failed, duration: 1), item("c", .failed, duration: 1, target: nil)]

        #expect(TestResultsPolicy.failures(cases) == [
            TestFailure(test: "Suite.b()", file: nil, path: nil, line: nil, message: "boom"),
            TestFailure(test: "Suite.c()", file: nil, path: nil, line: nil, message: "boom"),
        ])
        #expect(TestResultsPolicy.onlyTests(cases) == ["AppTests/Suite/b"])
    }

    @Test func attachmentsBelongToTheirTest() {
        let failed = item("b", .failed, duration: 1)
        let mine = TestAttachment(testIdentifier: "Suite/b()", name: "a", path: "/a.png", isAssociatedWithFailure: true)
        let other = TestAttachment(testIdentifier: "Suite/a()", name: "b", path: "/b.png", isAssociatedWithFailure: false)

        #expect(TestResultsPolicy.attachments([mine, other], of: failed) == [mine])
    }
}
