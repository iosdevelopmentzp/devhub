import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct JiraClientTests {
    @Test func readsAskForRawJSON() {
        #expect(JiraClient.versionArguments() == ["version"])
        #expect(JiraClient.meArguments() == ["me"])
        #expect(JiraClient.issueViewArguments(key: "ABC-123") == ["issue", "view", "ABC-123", "--raw"])
        #expect(JiraClient.issueListArguments(jql: "assignee = currentUser()", project: "ABC", order: .updated, limit: 50) == [
            "issue", "list", "-q", "assignee = currentUser()", "--raw", "--paginate", "0:50", "--order-by", "updated", "-p", "ABC",
        ])
        #expect(JiraClient.issueListArguments(jql: "statusCategory != Done", project: nil, order: .priority, limit: 20) == [
            "issue", "list", "-q", "statusCategory != Done", "--raw", "--paginate", "0:20", "--order-by", "priority",
        ])
    }

    @Test func aMovePassesTheStatusAsOneArgument() {
        #expect(JiraClient.moveArguments(key: "ABC-123", status: "In Progress") == ["issue", "move", "ABC-123", "In Progress"])
    }

    @Test func assignAndCommentPassTheirValuesAsArguments() {
        #expect(JiraClient.assignArguments(key: "ABC-123", user: "alex@example.com") == ["issue", "assign", "ABC-123", "alex@example.com"])
        #expect(JiraClient.commentArguments(key: "ABC-123", text: "-1 from me\nsecond line") == ["issue", "comment", "add", "--no-input", "--", "ABC-123", "-1 from me\nsecond line"])
    }

    @Test func onlyAFailedLoginAsksForTheShellVariables() {
        #expect(JiraClient.isLoginFailure(ShellResult(stdout: "", stderr: "The tool needs a Jira API token to function.", exitCode: 1)))
        #expect(JiraClient.isLoginFailure(ShellResult(stdout: "", stderr: "Error: 401 Unauthorized", exitCode: 1)))
        #expect(JiraClient.isLoginFailure(ShellResult(stdout: "alex", stderr: "", exitCode: 0)) == false)
        #expect(JiraClient.isLoginFailure(ShellResult(stdout: "", stderr: "Error: invalid JQL", exitCode: 1)) == false)
    }

    @Test func errorsAreMappedFromTheMessage() {
        #expect(JiraClient.error(exitCode: 127, message: "zsh: command not found: jira") == .notInstalled)
        #expect(JiraClient.error(exitCode: 1, message: "\u{1B}[0;33mThe tool needs a Jira API token to function.\u{1B}[0m") == .notLoggedIn)
        #expect(JiraClient.error(exitCode: 1, message: "Error: 401 Unauthorized") == .notLoggedIn)
        #expect(JiraClient.error(exitCode: 1, message: "jira config not found. Run jira init first") == .notConfigured)
        #expect(JiraClient.error(exitCode: 1, message: "\u{1B}[31mError: invalid transition state\u{1B}[0m\n") == .command("Error: invalid transition state"))
        #expect(JiraClient.error(exitCode: 1, message: "") == .command(""))
    }

    @Test func plainTextDropsTheColourCodes() {
        #expect(JiraClient.plainText("\u{1B}[0;33malex@example.com\u{1B}[0m\n") == "alex@example.com")
        #expect(JiraClient.plainText("plain") == "plain")
    }
}
