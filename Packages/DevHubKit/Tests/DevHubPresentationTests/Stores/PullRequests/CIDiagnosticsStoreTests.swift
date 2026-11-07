import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct CIDiagnosticsStoreTests {
    private let harness = StoreHarness()

    private var store: CIDiagnosticsStore {
        harness.ciDiagnostics
    }

    private func script() async {
        harness.spies.git.webURLResult = GitStateSample.webURL
        harness.spies.tools.existingFiles = [CIPolicy.circleCIConfigPath(checkoutPath: harness.worktrees.mainCheckoutPath)]
        harness.spies.git.stateResult = .success(GitStateSample.state)
        await harness.git.refresh()
        harness.spies.codeHost.openRequestsResult = .success(PullRequestList(username: "alex", requests: [PullRequestSummaryFixture.request(iid: 7, source: "feature/mine", state: .opened, author: "sam")], totalCount: 1))
        await harness.openPullRequests.refresh()
        harness.spies.ci.toolStateResult = .success(CIToolState(isInstalled: true, version: "1.14.0", isLoggedIn: true))
        harness.spies.redactionWords.wordsResult = .success([.word("Secretish")])
        let id = UUID()
        harness.commandLog.handle(CommandEvent(id: id, payload: .started(command: "circleci run list --branch APP-12-login --project-slug gh/team/app", cwd: "/Users/alex/Projects/app", kind: .read, operationID: nil)))
        harness.commandLog.handle(CommandEvent(id: id, payload: .output(["Secretish by sam at /Users/alex/Projects/app on feature/mine"])))
        harness.commandLog.handle(CommandEvent(id: id, payload: .finished(exitCode: 0, error: nil)))
        harness.commandLog.handle(CommandEvent(id: UUID(), payload: .started(command: "git status", cwd: nil, kind: .read, operationID: nil)))
        harness.activity.log("CircleCI: build-and-test failed", detail: "on feature/mine", outcome: .failure)
    }

    @Test func theTextIsRedactedBeforeItLeavesDevHub() async {
        await script()

        let text = await store.text(for: CIDiagnosticsSnapshot(requestReference: "#7"))

        #expect(text.contains("Provider: circleci\n"))
        #expect(text.contains("Slug: none\n"))
        #expect(text.contains("Host: gitlab\n"))
        #expect(text.contains("Branch: <branch-"))
        #expect(text.contains("CLI: circleci 1.14.0, logged in\n"))
        #expect(text.contains("## Commands (last 1 of circleci)\n"))
        #expect(text.contains("$ circleci run list --branch <branch-"))
        #expect(text.contains("--project-slug gh/<org>/<repo>\n"))
        #expect(text.contains("<redacted> by <user-"))
        #expect(text.contains("at ~/Projects/<repo> on <branch-"))
        #expect(text.contains("CircleCI: build-and-test failed — on <branch-"))
        #expect(text.contains("Secretish") == false)
        #expect(text.contains("team/app") == false)
        #expect(text.contains("feature/mine") == false)
        #expect(text.contains("/Users/alex") == false)
        #expect(text.contains("git status") == false)
        #expect(harness.spies.redactionWords.calls == 1)
        #expect(harness.spies.ci.calls.contains { call in
            guard case .toolState = call else { return false }
            return true
        })
    }

    @Test func copyPutsTheTextOnThePasteboardAndLogsIt() async {
        await script()

        await store.copy(CIDiagnosticsSnapshot())

        #expect(harness.copied.last?.hasPrefix("DevHub CI diagnostics\n") == true)
        #expect(harness.lastActivity?.title == "CI diagnostics copied")
        #expect(harness.lastActivity?.detail.hasSuffix("project names and branches replaced") == true)
        #expect(harness.lastActivity?.outcome == .info)
    }

    @Test func saveWritesTheChosenFile() async {
        await script()

        await store.save(CIDiagnosticsSnapshot())

        #expect(harness.requestedFileNames.count == 1)
        #expect(harness.requestedFileNames.first?.hasPrefix("DevHub CI diagnostics ") == true)
        #expect(harness.requestedFileNames.first?.hasSuffix(".txt") == true)
        #expect(harness.spies.textFiles.calls.count == 1)
        guard case .write(let text, let path) = harness.spies.textFiles.calls.first else {
            Issue.record("expected a write")
            return
        }
        #expect(path == "/tmp/DevHubTests/ci-diagnostics.txt")
        #expect(text.hasPrefix("DevHub CI diagnostics\n"))
        #expect(harness.lastActivity?.title == "CI diagnostics saved")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func aCancelledSavePanelWritesNothing() async {
        await script()
        harness.saveTarget = nil

        await store.save(CIDiagnosticsSnapshot())

        #expect(harness.spies.textFiles.calls.isEmpty)
        #expect(harness.spies.ci.calls.isEmpty)
    }

    @Test func aWriteFailureIsLogged() async {
        await script()
        harness.spies.textFiles.writeError = TestError.scripted("read only")

        await store.save(CIDiagnosticsSnapshot())

        #expect(harness.lastActivity?.title == "Cannot save the CI diagnostics")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func missingRedactionWordsAreLoggedAndTheSubjectsStillApply() async {
        await script()
        harness.spies.redactionWords.wordsResult = .failure(TestError.scripted("no file"))

        let text = await store.text(for: CIDiagnosticsSnapshot())

        #expect(text.contains("Secretish by <user-"))
        #expect(harness.activityTitles.contains("Cannot read the redaction words"))
    }

    @Test func withoutAProviderTheToolIsNotAsked() async {
        await script()
        harness.spies.tools.existingFiles = []

        let text = await store.text(for: CIDiagnosticsSnapshot())

        #expect(text.contains("Provider: none\n"))
        #expect(text.contains("CLI: not checked\n"))
        #expect(harness.spies.ci.calls.isEmpty)
    }
}
