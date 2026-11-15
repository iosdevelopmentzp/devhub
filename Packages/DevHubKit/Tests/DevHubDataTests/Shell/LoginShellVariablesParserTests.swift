import Foundation
import Testing
@testable import DevHubData

@Suite struct LoginShellVariablesParserTests {
    @Test func theScriptSourcesTheRcFileQuietlyAndPrintsOnlyTheNames() {
        let script = LoginShellVariablesParser.script(["JIRA_API_TOKEN", "JIRA_AUTH_TYPE", "bad name; rm"])

        #expect(script.hasPrefix("source \"${ZDOTDIR:-$HOME}/.zshrc\" </dev/null >/dev/null 2>&1;"))
        #expect(script.contains("for name in JIRA_API_TOKEN JIRA_AUTH_TYPE; do"))
        #expect(script.contains("rm") == false)
    }

    @Test func variablesAfterTheMarkerAreReadAndNoiseBeforeItIsDropped() {
        let output = "Welcome!\nJIRA_API_TOKEN=fake\n\u{1E}JIRA_API_TOKEN=abc=def\0JIRA_AUTH_TYPE=bearer\0"

        let variables = LoginShellVariablesParser.variables(in: output, names: ["JIRA_API_TOKEN", "JIRA_AUTH_TYPE"])

        #expect(variables == ["JIRA_API_TOKEN": "abc=def", "JIRA_AUTH_TYPE": "bearer"])
    }

    @Test func unknownNamesEmptyValuesAndAMissingMarkerGiveNothing() {
        #expect(LoginShellVariablesParser.variables(in: "\u{1E}OTHER=1\0JIRA_API_TOKEN=\0", names: ["JIRA_API_TOKEN"]).isEmpty)
        #expect(LoginShellVariablesParser.variables(in: "JIRA_API_TOKEN=abc", names: ["JIRA_API_TOKEN"]).isEmpty)
        #expect(LoginShellVariablesParser.variables(in: "", names: ["JIRA_API_TOKEN"]).isEmpty)
    }

    @Test func onlyShellNamesAreValid() {
        #expect(LoginShellVariablesParser.isValidName("JIRA_API_TOKEN"))
        #expect(LoginShellVariablesParser.isValidName("_private1"))
        #expect(LoginShellVariablesParser.isValidName("1ABC") == false)
        #expect(LoginShellVariablesParser.isValidName("") == false)
        #expect(LoginShellVariablesParser.isValidName("A B") == false)
        #expect(LoginShellVariablesParser.isValidName("A$(x)") == false)
    }
}
