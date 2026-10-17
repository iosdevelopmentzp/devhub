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

    @Test func theToolNameReachesTheMessage() {
        #expect(CodeHostErrorMapper.error(tool: "gh", exitCode: 1, message: "gh auth login required", host: "github.com").errorDescription == "gh is not logged in to github.com. Run gh auth login --hostname github.com")
        #expect(PullRequestError.notInstalled(tool: "gh").errorDescription == "gh is not installed. brew install gh")
    }
}
