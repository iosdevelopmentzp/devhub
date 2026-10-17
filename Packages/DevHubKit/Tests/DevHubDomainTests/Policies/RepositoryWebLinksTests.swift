import Foundation
import Testing
@testable import DevHubDomain

@Suite struct RepositoryWebLinksTests {
    @Test func gitHubBranchUsesTree() throws {
        let url = RepositoryWebLinks.branchURL(base: try github(), branch: "origin/feature/login", remote: "origin")

        #expect(url?.absoluteString == "https://github.com/org/app/tree/feature/login")
    }

    @Test func gitLabBranchUsesDashTree() throws {
        let url = RepositoryWebLinks.branchURL(base: try gitlab(), branch: "feature/login", remote: "origin")

        #expect(url?.absoluteString == "https://gitlab.example.com/org/app/-/tree/feature/login")
    }

    @Test func selfHostedGitHubHostIsTreatedAsGitHub() throws {
        let base = try #require(URL(string: "https://github.example.com/org/app"))

        #expect(RepositoryWebLinks.branchURL(base: base, branch: "dev", remote: "origin")?.absoluteString == "https://github.example.com/org/app/tree/dev")
    }

    @Test func gitHubMergeRequestUsesCompare() throws {
        let url = RepositoryWebLinks.newMergeRequestURL(base: try github(), branch: "origin/feature/login", baseName: "dev", remote: "origin")

        #expect(url?.absoluteString == "https://github.com/org/app/compare/dev...feature/login?expand=1")
    }

    @Test func gitLabMergeRequestUsesTheNewMergeRequestForm() throws {
        let url = RepositoryWebLinks.newMergeRequestURL(base: try gitlab(), branch: "feature/login", baseName: "dev", remote: "origin")

        let expected = "https://gitlab.example.com/org/app/-/merge_requests/new"
            + "?merge_request%5Bsource_branch%5D=feature/login&merge_request%5Btarget_branch%5D=dev"
        #expect(url?.absoluteString == expected)
    }

    @Test func mergeRequestEncodesTheBranchName() throws {
        let url = RepositoryWebLinks.newMergeRequestURL(base: try github(), branch: "fix space", baseName: "dev", remote: "origin")

        #expect(url?.absoluteString == "https://github.com/org/app/compare/dev...fix%20space?expand=1")
    }

    @Test func commitLinkFollowsTheHost() throws {
        #expect(RepositoryWebLinks.commitURL(base: try gitlab(), hash: "a1b2c3")?.absoluteString == "https://gitlab.example.com/org/app/-/commit/a1b2c3")
        #expect(RepositoryWebLinks.commitURL(base: try github(), hash: "a1b2c3")?.absoluteString == "https://github.com/org/app/commit/a1b2c3")
    }

    private func github() throws -> URL {
        try #require(URL(string: "https://github.com/org/app"))
    }

    private func gitlab() throws -> URL {
        try #require(URL(string: "https://gitlab.example.com/org/app"))
    }
}
