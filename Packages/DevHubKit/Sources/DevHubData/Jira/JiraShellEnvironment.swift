import Foundation
import DevHubDomain

actor JiraShellEnvironment {
    static let names = ["JIRA_API_TOKEN", "JIRA_AUTH_TYPE", "JIRA_CONFIG_FILE"]

    let variables: LoginShellVariables
    private(set) var isNeeded = false

    init(variables: LoginShellVariables) {
        self.variables = variables
    }

    func read() async -> [String: String] {
        await variables.read(Self.names)
    }

    func markNeeded() {
        isNeeded = true
    }
}
