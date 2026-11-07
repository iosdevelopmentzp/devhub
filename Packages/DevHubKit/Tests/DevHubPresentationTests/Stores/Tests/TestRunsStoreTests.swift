import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct TestRunsStoreTests {
    private let harness = StoreHarness()
    private let worktree = WorktreeSample.feature

    private var store: TestRunsStore {
        harness.testRuns
    }

    private func prepare(simulators: [SimulatorGroup] = SimulatorSample.groups) async {
        harness.simulators.groups = simulators
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, worktree])
        await harness.worktrees.refresh()
        harness.build.setScheme("AppTests")
    }

    private func finished() async throws {
        try await waitUntil { [store, worktree, harness] in store.runs[worktree.id]?.isRunning == false && harness.lastActivity != nil }
    }

    @Test func runsTheTestsOfTheWorktreeOnTheTargetSimulator() async throws {
        await prepare()
        harness.spies.testRuns.runEvents = [
            .step("Running tests"),
            .testFinished(TestCaseResult(suite: "LoginTests", name: "testLogin", status: .passed, duration: 0.1)),
            .testFinished(TestCaseResult(suite: "LoginTests", name: "testLogout", status: .failed, duration: 0.1)),
            .testFinished(TestCaseResult(suite: nil, name: "watch", status: .skipped, duration: nil)),
            .failure(TestFailure(test: "LoginTests.testLogout", file: "LoginTests.swift", path: "/repo/LoginTests.swift", line: 9, message: "boom")),
            .failure(TestFailure(test: "LoginTests.testLogout", file: "LoginTests.swift", path: "/repo/LoginTests.swift", line: 9, message: "boom")),
        ]
        harness.spies.testRuns.runResult = .success(TestRunReport(status: .failed, resultBundlePath: "/tmp/App.xcresult"))

        store.run(worktreeID: worktree.id)
        try await finished()

        let run = try #require(store.runs[worktree.id])
        #expect(run.passed == 1)
        #expect(run.failed == 1)
        #expect(run.skipped == 1)
        #expect(run.failures.count == 1)
        #expect(run.resultBundlePath == "/tmp/App.xcresult")
        guard case .finished(.failed, _) = run.phase else { Issue.record("Expected a finished failed run, got \(run.phase)"); return }
        let request = TestRunRequest(projectPath: worktree.path, container: nil, scheme: "AppTests", configuration: "Debug", simulatorUDID: SimulatorSample.booted.id, simulatorName: SimulatorSample.booted.name)
        #expect(harness.spies.testRuns.calls == [.run(request), .results(bundlePath: "/tmp/App.xcresult", projectPath: worktree.path)])
        #expect(harness.spies.simulators.calls.contains(.boot(udid: SimulatorSample.booted.id)))
        #expect(harness.lastActivity?.title == "Tests failed: feature/login")
        #expect(harness.lastActivity?.detail == "1 passed · 1 failed · 1 skipped · AppTests · iPhone 17")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func writeFixPromptSavesTheFailedTestsOfTheLastRun() async throws {
        await prepare()
        harness.spies.testRuns.runEvents = [
            .testFinished(TestCaseResult(suite: "LoginTests", name: "testLogout", status: .failed, duration: 0.1)),
            .failure(TestFailure(test: "LoginTests.testLogout", file: "LoginTests.swift", path: "/repo/LoginTests.swift", line: 9, message: "boom")),
        ]
        harness.spies.testRuns.runResult = .success(TestRunReport(status: .failed, resultBundlePath: nil))
        harness.spies.reviewPrompts.saveResult = .success("/tmp/prompts/fix-tests-feature-login.md")
        store.run(worktreeID: worktree.id)
        try await finished()

        let path = await store.writeFixPrompt(worktreeID: worktree.id)

        #expect(path == "/tmp/prompts/fix-tests-feature-login.md")
        let prompt = try #require(harness.spies.reviewPrompts.savedPrompts.first)
        #expect(prompt.hasPrefix("# Failed tests of AppTests in feature/login"))
        #expect(prompt.contains("## Failure 1: `LoginTests.testLogout` (`LoginTests.swift:9`)"))
        #expect(harness.spies.reviewPrompts.calls.first == .saveNamed(prompt, name: "fix-tests-feature-login"))
    }

    @Test func writeFixPromptAfterAPassedRunSaysNothingToFix() async throws {
        await prepare()
        harness.spies.testRuns.runEvents = [.testFinished(TestCaseResult(suite: nil, name: "a", status: .passed, duration: 0.1))]
        store.run(worktreeID: worktree.id)
        try await finished()

        let path = await store.writeFixPrompt(worktreeID: worktree.id)

        #expect(path == nil)
        #expect(harness.lastActivity?.title == "Nothing to fix in feature/login")
        #expect(harness.spies.reviewPrompts.calls.isEmpty)
    }

    @Test func aPassedRunLogsSuccess() async throws {
        await prepare()
        harness.spies.testRuns.runEvents = [.testFinished(TestCaseResult(suite: nil, name: "a", status: .passed, duration: 0.1))]

        store.run(worktreeID: worktree.id)
        try await finished()

        #expect(harness.lastActivity?.title == "Tests passed: feature/login")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func withoutASimulatorNothingRuns() async {
        await prepare(simulators: [])

        store.run(worktreeID: worktree.id)
        await harness.settle()

        #expect(store.runs.isEmpty)
        #expect(harness.spies.testRuns.calls.isEmpty)
        #expect(harness.lastActivity?.title == "No simulator for the tests")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aMissingWorktreeDoesNotRun() async {
        harness.simulators.groups = SimulatorSample.groups
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.missing])
        await harness.worktrees.refresh()

        store.run(worktreeID: WorktreeSample.missing.id)
        await harness.settle()

        #expect(store.runs.isEmpty)
        #expect(harness.spies.testRuns.calls.isEmpty)
    }

    @Test func aRunThatCannotStartKeepsTheMessage() async throws {
        await prepare()
        harness.spies.testRuns.runResult = .failure(TestRunError.failed("cannot find 'x' in scope"))
        harness.spies.testRuns.runEvents = [.issue(BuildIssue(severity: .error, path: "/repo/Login.swift", line: 3, column: nil, message: "cannot find 'x' in scope"))]

        store.run(worktreeID: worktree.id)
        try await finished()

        let run = try #require(store.runs[worktree.id])
        guard case .notRun(let message, _) = run.phase else { Issue.record("Expected notRun, got \(run.phase)"); return }
        #expect(message == "cannot find 'x' in scope")
        #expect(run.issues.count == 1)
        #expect(harness.lastActivity?.title == "Tests did not run: feature/login")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func cancelRemovesTheRunAndLogsIt() async throws {
        await prepare()
        harness.spies.testRuns.runDelay = .seconds(30)

        store.run(worktreeID: worktree.id)
        try await waitUntil { [store, worktree] in store.isRunning(worktree.id) }
        store.cancel(worktreeID: worktree.id)
        try await waitUntil { [store, worktree] in store.runs[worktree.id] == nil }

        #expect(harness.lastActivity?.title == "Tests cancelled")
        #expect(harness.lastActivity?.outcome == .info)
    }

    @Test func aSecondRunWhileRunningIsIgnored() async throws {
        await prepare()
        harness.spies.testRuns.runDelay = .seconds(30)

        store.run(worktreeID: worktree.id)
        try await waitUntil { [store, worktree] in store.isRunning(worktree.id) }
        store.run(worktreeID: worktree.id)
        await harness.settle()

        #expect(harness.spies.testRuns.calls.count == 1)
        store.cancel(worktreeID: worktree.id)
    }

    @Test func dismissHidesAFinishedRunOnly() async throws {
        await prepare()
        store.run(worktreeID: worktree.id)
        try await finished()

        store.dismiss(worktreeID: worktree.id)

        #expect(store.runs.isEmpty)
    }

    @Test func aProjectChangeClearsTheRuns() async throws {
        await prepare()
        store.run(worktreeID: worktree.id)
        try await finished()

        harness.events.post(.projectChanged)

        #expect(store.runs.isEmpty)
    }

    @Test func aRemovedWorktreeLosesItsRun() async throws {
        await prepare()
        store.run(worktreeID: worktree.id)
        try await finished()

        harness.spies.worktrees.listResult = .success([WorktreeSample.main])
        await harness.worktrees.refresh()

        #expect(store.runs.isEmpty)
    }

    private var bundleCases: [TestResultCase] {
        [
            TestResultCase(identifier: "LoginTests/testLogin()", target: "AppTests", suite: "LoginTests", name: "testLogin()", status: .passed, duration: 2),
            TestResultCase(identifier: "LoginTests/testLogout()", target: "AppTests", suite: "LoginTests", name: "testLogout()", status: .failed, duration: 0.5, failureMessage: "boom", file: "LoginTests.swift", path: "/repo/LoginTests.swift", line: 9),
            TestResultCase(identifier: "FeedTests/testFeed()", target: "AppTests", suite: "FeedTests", name: "testFeed()", status: .failed, duration: 0.1, failureMessage: "crashed"),
        ]
    }

    @Test func theBundleIsTheSourceAfterTheRun() async throws {
        await prepare()
        harness.spies.testRuns.runEvents = [.testFinished(TestCaseResult(suite: "LoginTests", name: "testLogout", status: .failed, duration: 0.1))]
        harness.spies.testRuns.runResult = .success(TestRunReport(status: .failed, resultBundlePath: "/tmp/App.xcresult"))
        harness.spies.testRuns.resultsResult = .success(bundleCases)
        harness.spies.testRuns.attachmentsResult = .success([
            TestAttachment(testIdentifier: "LoginTests/testLogout()", name: "Failure", path: "/tmp/a/failure.png", isAssociatedWithFailure: true),
            TestAttachment(testIdentifier: "LoginTests/testLogin()", name: "Kept", path: "/tmp/a/kept.png", isAssociatedWithFailure: false),
        ])

        store.run(worktreeID: worktree.id)
        try await finished()

        let run = try #require(store.runs[worktree.id])
        #expect(run.passed == 1)
        #expect(run.failed == 2)
        #expect(run.failures.map(\.test) == ["LoginTests.testLogout()", "FeedTests.testFeed()"])
        #expect(run.failures.first?.path == "/repo/LoginTests.swift")
        #expect(run.attachments.map(\.path) == ["/tmp/a/failure.png"])
        #expect(harness.spies.testRuns.calls.last == .exportAttachments(bundlePath: "/tmp/App.xcresult"))
        #expect(harness.lastActivity?.detail == "1 passed · 2 failed · AppTests · iPhone 17")
    }

    @Test func runFailedAgainRunsOnlyTheFailedTests() async throws {
        await prepare()
        harness.spies.testRuns.runResult = .success(TestRunReport(status: .failed, resultBundlePath: "/tmp/App.xcresult"))
        harness.spies.testRuns.resultsResult = .success(bundleCases)
        store.run(worktreeID: worktree.id)
        try await finished()
        harness.spies.testRuns.resultsResult = .success([])

        store.runFailedAgain(worktreeID: worktree.id)
        try await waitUntil { [harness] in harness.spies.testRuns.calls.filter { if case .run = $0 { return true } else { return false } }.count == 2 }
        try await finished()

        let request = TestRunRequest(projectPath: worktree.path, container: nil, scheme: "AppTests", configuration: "Debug", simulatorUDID: SimulatorSample.booted.id, simulatorName: SimulatorSample.booted.name, onlyTests: ["AppTests/LoginTests/testLogout", "AppTests/FeedTests/testFeed"])
        #expect(harness.spies.testRuns.calls.contains(.run(request)))
    }

    @Test func aBundleThatCannotBeReadKeepsTheTextResult() async throws {
        await prepare()
        harness.spies.testRuns.runEvents = [
            .testFinished(TestCaseResult(suite: "LoginTests", name: "testLogout", status: .failed, duration: 0.1)),
            .failure(TestFailure(test: "LoginTests.testLogout", file: "LoginTests.swift", path: "/repo/LoginTests.swift", line: 9, message: "boom")),
        ]
        harness.spies.testRuns.runResult = .success(TestRunReport(status: .failed, resultBundlePath: "/tmp/App.xcresult"))
        harness.spies.testRuns.resultsResult = .failure(TestRunError.failed("no bundle"))

        store.run(worktreeID: worktree.id)
        try await finished()

        #expect(store.runs[worktree.id]?.failures.map(\.test) == ["LoginTests.testLogout"])
        #expect(harness.activityTitles.contains("Cannot read the test results of feature/login"))
        store.runFailedAgain(worktreeID: worktree.id)
        #expect(harness.spies.testRuns.calls.filter { if case .run = $0 { return true } else { return false } }.count == 1)
    }
}
