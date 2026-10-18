import Foundation
import Testing
@testable import DevHubDomain

@Suite struct RepositoryWebLinksTests {
    @Test func gitHubBranchUsesTree() throws {
        let url = RepositoryWebLinks.branchURL(base: try github(), kind: nil, branch: "origin/feature/login", remote: "origin")

        #expect(url?.absoluteString == "https://github.com/org/app/tree/feature/login")
    }

    @Test func gitLabBranchUsesDashTree() throws {
        let url = RepositoryWebLinks.branchURL(base: try gitlab(), kind: nil, branch: "feature/login", remote: "origin")

        #expect(url?.absoluteString == "https://gitlab.example.com/org/app/-/tree/feature/login")
    }

    @Test func selfHostedGitHubHostIsTreatedAsGitHub() throws {
        let base = try #require(URL(string: "https://github.example.com/org/app"))

        #expect(RepositoryWebLinks.branchURL(base: base, kind: nil, branch: "dev", remote: "origin")?.absoluteString == "https://github.example.com/org/app/tree/dev")
    }

    @Test func gitHubPullRequestUsesCompare() throws {
        let url = RepositoryWebLinks.newPullRequestURL(base: try github(), kind: nil, branch: "origin/feature/login", baseName: "dev", remote: "origin")

        #expect(url?.absoluteString == "https://github.com/org/app/compare/dev...feature/login?expand=1")
    }

    @Test func gitLabPullRequestUsesTheNewPullRequestForm() throws {
        let url = RepositoryWebLinks.newPullRequestURL(base: try gitlab(), kind: nil, branch: "feature/login", baseName: "dev", remote: "origin")

        let expected = "https://gitlab.example.com/org/app/-/merge_requests/new"
            + "?merge_request%5Bsource_branch%5D=feature/login&merge_request%5Btarget_branch%5D=dev"
        #expect(url?.absoluteString == expected)
    }

    @Test func pullRequestEncodesTheBranchName() throws {
        let url = RepositoryWebLinks.newPullRequestURL(base: try github(), kind: nil, branch: "fix space", baseName: "dev", remote: "origin")

        #expect(url?.absoluteString == "https://github.com/org/app/compare/dev...fix%20space?expand=1")
    }

    @Test func commitLinkFollowsTheHost() throws {
        #expect(RepositoryWebLinks.commitURL(base: try gitlab(), kind: nil, hash: "a1b2c3")?.absoluteString == "https://gitlab.example.com/org/app/-/commit/a1b2c3")
        #expect(RepositoryWebLinks.commitURL(base: try github(), kind: nil, hash: "a1b2c3")?.absoluteString == "https://github.com/org/app/commit/a1b2c3")
    }

    @Test func theConfiguredKindWinsOverTheHostName() throws {
        let enterprise = try #require(URL(string: "https://code.example.com/org/app"))

        #expect(RepositoryWebLinks.commitURL(base: enterprise, kind: .github, hash: "a1b2c3")?.absoluteString == "https://code.example.com/org/app/commit/a1b2c3")
        #expect(RepositoryWebLinks.branchURL(base: enterprise, kind: .github, branch: "dev", remote: "origin")?.absoluteString == "https://code.example.com/org/app/tree/dev")
        #expect(RepositoryWebLinks.commitURL(base: enterprise, kind: nil, hash: "a1b2c3")?.absoluteString == "https://code.example.com/org/app/-/commit/a1b2c3")
    }

    private func github() throws -> URL {
        try #require(URL(string: "https://github.com/org/app"))
    }

    private func gitlab() throws -> URL {
        try #require(URL(string: "https://gitlab.example.com/org/app"))
    }
}
