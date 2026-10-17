import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GlabErrorMapperTests {
    @Test(arguments: [
        (Int32(127), "anything", MergeRequestError.notInstalled),
        (1, "zsh: command not found: glab", .notInstalled),
        (1, "env: glab: No such file or directory", .notInstalled),
        (1, "HTTP 401 Unauthorized", .notLoggedIn(host: "gitlab.com")),
        (1, "invalid Token", .notLoggedIn(host: "gitlab.com")),
        (1, "run glab AUTH login", .notLoggedIn(host: "gitlab.com")),
        (1, "404 Not Found", .command("404 Not Found")),
    ])
    func mapsExitCodeAndMessage(exitCode: Int32, message: String, expected: MergeRequestError) {
        #expect(GlabErrorMapper.error(exitCode: exitCode, message: message, host: "gitlab.com") == expected)
    }
}
