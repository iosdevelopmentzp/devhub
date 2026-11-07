import Foundation
import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct TestRunPanelMapperTests {
    private let started = Date(timeIntervalSince1970: 1_800_000_000)
    private let failure = TestFailure(test: "LoginTests.testLogin", file: "LoginTests.swift", path: "/repo/Tests/LoginTests.swift", line: 42, message: "XCTAssertEqual failed")

    private func run(_ phase: TestRun.Phase) -> TestRun {
        TestRun(scheme: "App", simulatorName: "iPhone 17", startedAt: started, phase: phase)
    }

    @Test func aRunningRunShowsTheStepAndLiveCounts() {
        var run = run(.running(step: "Running tests"))
        run.passed = 3
        run.failed = 1

        let model = TestRunPanelMapper.model(for: run)

        #expect(model.title == "Testing App on iPhone 17…")
        #expect(model.step == "Running tests")
        #expect(model.detail == "3 passed · 1 failed")
        #expect(model.isRunning)
        #expect(model.canRunAgain == false)
        #expect(model.tint == .blue)
    }

    @Test func aRunningRunWithoutResultsHasNoCounts() {
        #expect(TestRunPanelMapper.model(for: run(.running(step: "Compiling"))).detail == nil)
    }

    @Test func aPassedRunIsGreenWithCountsDurationAndSimulator() {
        var run = run(.finished(.passed, started.addingTimeInterval(4.2)))
        run.passed = 11
        run.skipped = 1
        run.resultBundlePath = "/tmp/App.xcresult"

        let model = TestRunPanelMapper.model(for: run)

        #expect(model.title == "Tests passed · App")
        #expect(model.icon == "checkmark.diamond.fill")
        #expect(model.tint == .green)
        #expect(model.detail == "11 passed · 1 skipped · 4.2 s · iPhone 17")
        #expect(model.failuresTitle == nil)
        #expect(model.resultBundlePath == "/tmp/App.xcresult")
        #expect(model.canRunAgain)
    }

    @Test func aFailedRunListsTheFailuresWithTheirLocation() {
        var run = run(.finished(.failed, started.addingTimeInterval(1)))
        run.passed = 10
        run.failed = 1
        run.failures = [failure, TestFailure(test: "feed order", file: "FeedTests.swift", path: nil, line: 7, message: "Expectation failed")]

        let model = TestRunPanelMapper.model(for: run)

        #expect(model.title == "Tests failed · App")
        #expect(model.tint == .red)
        #expect(model.failuresTitle == "2 failed tests")
        #expect(model.failures[0] == TestFailureRowModel(id: 0, test: "LoginTests.testLogin", location: "LoginTests.swift:42", message: "XCTAssertEqual failed", path: "/repo/Tests/LoginTests.swift", line: 42, hint: "Open /repo/Tests/LoginTests.swift at line 42"))
        #expect(model.failures[1].location == "FeedTests.swift:7")
        #expect(model.failures[1].path == nil)
        #expect(model.failures[1].hint == "Expectation failed")
    }

    @Test func aRunThatDidNotStartShowsTheMessageAndTheCompilerIssues() {
        var run = run(.notRun("xcodebuild exited with code 65.", started.addingTimeInterval(1)))
        run.issues = [BuildIssue(severity: .error, path: "/repo/Login.swift", line: 3, column: nil, message: "cannot find 'x' in scope")]

        let model = TestRunPanelMapper.model(for: run)

        #expect(model.title == "Tests did not run · App")
        #expect(model.tint == .orange)
        #expect(model.detail == "xcodebuild exited with code 65.")
        #expect(model.issuesTitle == "1 error")
        #expect(model.issues.first?.location == "Login.swift:3")
    }

    @Test func canFixOnlyAfterARunWithFailuresOrIssues() {
        var failed = run(.finished(.failed, started))
        failed.failures = [failure]
        var broken = run(.notRun("exit 65", started))
        broken.issues = [BuildIssue(severity: .error, path: nil, line: nil, column: nil, message: "boom")]
        var running = run(.running(step: "Running tests"))
        running.failures = [failure]

        #expect(TestRunPanelMapper.model(for: failed).canFix)
        #expect(TestRunPanelMapper.model(for: broken).canFix)
        #expect(TestRunPanelMapper.model(for: running).canFix == false)
        #expect(TestRunPanelMapper.model(for: run(.finished(.passed, started))).canFix == false)
    }

    @Test func noTestsRanIsSaidPlainly() {
        #expect(TestRunPanelMapper.model(for: run(.finished(.passed, started))).detail == "No tests ran · 0 ms · iPhone 17")
    }

    @Test func aFinishedRunWithBundleResultsShowsAttachmentsSlowestTestsAndRunFailedAgain() {
        var run = run(.finished(.failed, started.addingTimeInterval(3)))
        run.cases = [
            TestResultCase(identifier: "LoginTests/testLogin()", target: "AppTests", suite: "LoginTests", name: "testLogin()", status: .failed, duration: 0.4, failureMessage: "boom"),
            TestResultCase(identifier: "FeedTests/testFeed()", target: "AppTests", suite: "FeedTests", name: "testFeed()", status: .passed, duration: 2.5),
        ]
        run.failures = TestResultsPolicy.failures(run.cases)
        run.attachments = [TestAttachment(testIdentifier: "LoginTests/testLogin()", name: "Diff", path: "/tmp/a/diff.png", isAssociatedWithFailure: true)]

        let model = TestRunPanelMapper.model(for: run)

        #expect(model.failures.first?.attachments == [TestAttachmentRowModel(id: "/tmp/a/diff.png", name: "Diff", path: "/tmp/a/diff.png", isImage: true, hint: "Open Diff in Preview")])
        #expect(model.slowestTitle == "Slowest tests")
        #expect(model.slowest.map(\.title) == ["FeedTests.testFeed()", "LoginTests.testLogin()"])
        #expect(model.runFailedTitle == "Run 1 Failed Test Again")
    }

    @Test func aRunOfFailedTestsSaysSo() {
        var run = run(.running(step: "Running tests"))
        run.onlyTests = ["AppTests/LoginTests/testLogin", "AppTests/FeedTests/testFeed"]

        let model = TestRunPanelMapper.model(for: run)

        #expect(model.title == "Running 2 failed tests of App again…")
        #expect(model.slowestTitle == nil)
        #expect(model.runFailedTitle == nil)
    }
}
