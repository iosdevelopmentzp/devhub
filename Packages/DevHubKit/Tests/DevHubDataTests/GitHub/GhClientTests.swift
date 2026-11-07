import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhClientTests {
    @Test func graphqlPassesTypedVariablesWithCapitalF() {
        let arguments = GhClient.graphqlArguments(query: "query { x }", variables: [.text("owner", "example"), .typed("number", "7")], host: "github.com")

        #expect(arguments == ["api", "graphql", "--hostname", "github.com", "-f", "query=query { x }", "-f", "owner=example", "-F", "number=7"])
    }

    @Test func restPassesTheMethodAndFields() {
        let arguments = GhClient.restArguments(endpoint: "repos/example/app/pulls/7/update-branch", method: "PUT", fields: [], host: "github.com")

        #expect(arguments == ["api", "--hostname", "github.com", "-X", "PUT", "repos/example/app/pulls/7/update-branch"])
    }

    @Test func theRepositoryNamesTheHostOnlyOutsideGitHubDotCom() {
        let enterprise = CodeHost(kind: .github, host: "git.example.com", path: "team/app", webURL: URL(string: "https://git.example.com/team/app")!)

        #expect(GhClient.repository(.gitHubSample) == "example/app")
        #expect(GhClient.repository(enterprise) == "git.example.com/team/app")
        #expect(GhClient.owner(.gitHubSample) == "example")
        #expect(GhClient.name(.gitHubSample) == "app")
    }

    @Test func aPagedReadAsksForEveryPageInOneArray() {
        #expect(GhClient.pagedArguments(endpoint: "user/teams?per_page=100", host: "github.com") == ["api", "--hostname", "github.com", "--paginate", "--slurp", "user/teams?per_page=100"])
    }

    @Test func aLogReadAllowsEscapeSequences() {
        #expect(GhClient.logArguments(endpoint: "repos/example/app/actions/jobs/9/logs", host: "github.com") == ["api", "--hostname", "github.com", "--allow-escape-sequences", "repos/example/app/actions/jobs/9/logs"])
    }

    @Test func aRawReadAsksForTheRawMediaType() {
        #expect(GhClient.rawArguments(endpoint: "repos/example/app/contents/a.swift?ref=abc", host: "github.com") == ["api", "--hostname", "github.com", "-H", "Accept: application/vnd.github.raw+json", "repos/example/app/contents/a.swift?ref=abc"])
    }
}
