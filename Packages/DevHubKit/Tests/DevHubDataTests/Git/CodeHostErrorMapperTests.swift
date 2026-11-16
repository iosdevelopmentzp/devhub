import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct CodeHostErrorMapperTests {
    @Test(arguments: [
        (Int32(127), "anything", PullRequestError.notInstalled(tool: "glab")),
        (1, "zsh: command not found: glab", .notInstalled(tool: "glab")),
        (1, "env: glab: No such file or directory", .notInstalled(tool: "glab")),
        (1, "HTTP 401 Unauthorized", .notLoggedIn(tool: "glab", host: "gitlab.com")),
        (1, "invalid Token", .notLoggedIn(tool: "glab", host: "gitlab.com")),
        (1, "run glab AUTH login", .notLoggedIn(tool: "glab", host: "gitlab.com")),
        (1, "404 Not Found", .command("404 Not Found")),
    ])
    func mapsExitCodeAndMessage(exitCode: Int32, message: String, expected: PullRequestError) {
        #expect(CodeHostErrorMapper.error(tool: "glab", exitCode: exitCode, message: message, host: "gitlab.com") == expected)
    }

    @Test func aMissingScopeOfTheTokenAsksToRefreshTheLogin() {
        let message = "gh: Your token has not been granted the required scopes to execute this query. The 'updateSubscription' field requires one of the following scopes: ['notifications'], but your token has only been granted the: ['repo'] scopes."

        let error = CodeHostErrorMapper.error(tool: "gh", exitCode: 1, message: message, host: "github.com")

        #expect(error == .missingScope(tool: "gh", host: "github.com", scope: "notifications"))
        #expect(error.errorDescription == "The gh login has no notifications scope. Run gh auth refresh --hostname github.com --scopes notifications")
        #expect(CodeHostErrorMapper.missingScope(in: "INSUFFICIENT_SCOPES") == "notifications")
        #expect(CodeHostErrorMapper.missingScope(in: "404 Not Found") == nil)
    }

    @Test func theToolNameReachesTheMessage() {
        #expect(CodeHostErrorMapper.error(tool: "gh", exitCode: 1, message: "gh auth login required", host: "github.com").errorDescription == "gh is not logged in to github.com. Run gh auth login --hostname github.com")
        #expect(PullRequestError.notInstalled(tool: "gh").errorDescription == "gh is not installed. brew install gh")
    }
}
