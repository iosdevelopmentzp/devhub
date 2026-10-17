import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CodeHostPolicyTests {
    @Test func theKindComesFromTheHostName() throws {
        let githubURL = try #require(URL(string: "https://github.com/example/app"))
        let gitlabURL = try #require(URL(string: "https://gitlab.example.com/group/sub/app"))
        let github = try #require(CodeHostPolicy.codeHost(webURL: githubURL, kind: nil, name: nil))
        let gitlab = try #require(CodeHostPolicy.codeHost(webURL: gitlabURL, kind: nil, name: nil))

        #expect(github == CodeHost(kind: .github, host: "github.com", path: "example/app", webURL: githubURL))
        #expect(gitlab.kind == .gitlab)
        #expect(gitlab.path == "group/sub/app")
    }

    @Test func anUnknownHostIsGitLabUntilTheConfigSaysOtherwise() throws {
        let url = try #require(URL(string: "https://code.example.com/team/app"))

        #expect(CodeHostPolicy.codeHost(webURL: url, kind: nil, name: nil)?.kind == .gitlab)
        #expect(CodeHostPolicy.codeHost(webURL: url, kind: .github, name: "code.example.com")?.kind == .github)
        #expect(CodeHostPolicy.codeHost(webURL: url, kind: nil, name: "api.example.com")?.host == "api.example.com")
    }

    @Test func aURLWithoutAPathIsNoCodeHost() throws {
        let url = try #require(URL(string: "https://github.com"))

        #expect(CodeHostPolicy.codeHost(webURL: url, kind: nil, name: nil) == nil)
    }

    @Test func theWordsFollowTheKind() {
        let github = CodeHost(kind: .github, host: "github.com", path: "a/b", webURL: URL(fileURLWithPath: "/"))
        let gitlab = CodeHost(kind: .gitlab, host: "gitlab.com", path: "a/b", webURL: URL(fileURLWithPath: "/"))

        #expect([github.name, github.requestNoun, github.referencePrefix, github.tool] == ["GitHub", "pull request", "#", "gh"])
        #expect([gitlab.name, gitlab.requestNoun, gitlab.referencePrefix, gitlab.tool] == ["GitLab", "merge request", "!", "glab"])
    }

    @Test func theHostFieldsDecode() throws {
        let config = try ConfigDecoding.decode(ProjectConfig.self, from: ["git": ["host": ["kind": "github", "name": "code.example.com"]]])
        let settings = GitSettingsPolicy.settings(for: config)

        #expect(settings.hostKind == .github)
        #expect(settings.hostName == "code.example.com")
    }
}
