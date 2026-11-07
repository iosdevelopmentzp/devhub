import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct JiraClientTests {
    @Test func readsAskForRawJSON() {
        #expect(JiraClient.versionArguments() == ["version"])
        #expect(JiraClient.meArguments() == ["me"])
        #expect(JiraClient.issueViewArguments(key: "ABC-123") == ["issue", "view", "ABC-123", "--raw"])
        #expect(JiraClient.issueListArguments(jql: "assignee = currentUser()", project: "ABC", limit: 50) == [
            "issue", "list", "-q", "assignee = currentUser()", "--raw", "--paginate", "0:50", "--order-by", "updated", "-p", "ABC",
        ])
        #expect(JiraClient.issueListArguments(jql: "statusCategory != Done", project: nil, limit: 20) == [
            "issue", "list", "-q", "statusCategory != Done", "--raw", "--paginate", "0:20", "--order-by", "updated",
        ])
    }

    @Test func aMovePassesTheStatusAsOneArgument() {
        #expect(JiraClient.moveArguments(key: "ABC-123", status: "In Progress") == ["issue", "move", "ABC-123", "In Progress"])
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
