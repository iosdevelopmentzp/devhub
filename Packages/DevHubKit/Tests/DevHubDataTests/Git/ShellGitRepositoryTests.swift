import Foundation
import Testing
@testable import DevHubData

@Suite struct ShellGitRepositoryTests {
    @Test(arguments: [
        ("git@gitlab.com:group/app.git", "https://gitlab.com/group/app"),
        ("git@github.com:org/sub/app", "https://github.com/org/sub/app"),
        ("ssh://git@gitlab.example.com/group/app.git", "https://gitlab.example.com/group/app"),
        ("ssh://gitlab.example.com/group/app.git", "https://gitlab.example.com/group/app"),
        ("ssh://git@gitlab.example.com:2222/group/app.git", "https://gitlab.example.com:2222/group/app"),
        ("https://gitlab.com/group/app.git", "https://gitlab.com/group/app"),
        ("https://gitlab.com/group/app", "https://gitlab.com/group/app"),
    ])
    func webURLFromRemote(remote: String, expected: String) {
        #expect(ShellGitRepository.webURL(fromRemote: remote) == URL(string: expected))
    }
}
