import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIClientTests {
    @Test func readsAskForJSON() {
        #expect(CircleCIClient.versionArguments() == ["version", "--json"])
        #expect(CircleCIClient.settingArguments() == ["setting", "list", "--json"])
        #expect(CircleCIClient.workflowArguments(id: "w1") == ["workflow", "get", "w1", "--json"])
        #expect(CircleCIClient.runListArguments(branch: "main", limit: 10, slug: nil) == ["run", "list", "--branch", "main", "--limit", "10", "--json"])
        #expect(CircleCIClient.jobOutputArguments(jobID: "j1") == ["job", "output", "list", "j1", "--json"])
        #expect(CircleCIClient.testResultArguments(jobID: "j1") == ["testresult", "list", "j1", "--json"])
    }

    @Test func theFlakyTestsComeFromTheInsightsAPI() {
        #expect(CircleCIClient.flakyTestsArguments(slug: "gh/example/app") == ["api", "api/v2/insights/gh/example/app/flaky-tests"])
    }

    @Test func actionsSkipThePromptAndAskForJSON() {
        #expect(CircleCIClient.rerunArguments(workflowID: "w1", fromFailed: true) == ["workflow", "rerun", "w1", "--from-failed", "--json"])
        #expect(CircleCIClient.rerunArguments(workflowID: "w1", fromFailed: false) == ["workflow", "rerun", "w1", "--json"])
        #expect(CircleCIClient.cancelArguments(workflowID: "w1") == ["workflow", "cancel", "w1", "--force"])
        #expect(CircleCIClient.approveArguments(runID: "r1", job: "approve-release", slug: nil) == ["run", "approve", "r1", "--job", "approve-release", "--force", "--json"])
    }

    @Test func onlyRunListAndApproveTakeTheProjectFlag() {
        #expect(CircleCIClient.runListArguments(branch: "main", limit: 5, slug: "gh/example/app") == ["run", "list", "--branch", "main", "--limit", "5", "--json", "--project", "gh/example/app"])
        #expect(CircleCIClient.approveArguments(runID: "r1", job: "a", slug: "gh/example/app") == ["run", "approve", "r1", "--job", "a", "--force", "--json", "--project", "gh/example/app"])
        #expect(CircleCIClient.approveArguments(runID: "r1", job: "a", slug: "") == ["run", "approve", "r1", "--job", "a", "--force", "--json"])
    }

    @Test func errorsNameTheMissingToolOrTheLogin() {
        #expect(CircleCIClient.error(exitCode: 127, message: "env: circleci: No such file or directory") == .notInstalled)
        #expect(CircleCIClient.error(exitCode: 1, message: "You are not logged in. Run circleci auth login first.") == .notLoggedIn)
        #expect(CircleCIClient.error(exitCode: 4, message: "401 Unauthorized") == .notLoggedIn)
        #expect(CircleCIClient.error(exitCode: 1, message: "workflow not found") == .command("workflow not found"))
    }
}
