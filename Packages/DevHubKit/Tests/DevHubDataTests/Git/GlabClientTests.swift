import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabClientTests {
    @Test func aCommandNamesTheProjectByItsWebAddress() {
        #expect(GlabClient.commandArguments(["mr", "update", "1"], repository: .gitLabSample) == ["mr", "update", "1", "--repo", CodeHost.gitLabSample.webURL.absoluteString])
    }

    @Test func graphqlPassesTheQueryAndVariablesAsFields() {
        let arguments = GlabClient.graphqlArguments(
            query: "query { x }",
            variables: [(name: "path", value: "team/app"), (name: "iid", value: "7")],
            host: "gitlab.example.com"
        )

        #expect(arguments == ["api", "graphql", "--hostname", "gitlab.example.com", "-f", "query=query { x }", "-f", "path=team/app", "-f", "iid=7"])
    }

    @Test func graphqlSendsBooleansAsTypedFields() {
        let arguments = GlabClient.graphqlArguments(
            query: "mutation { x }",
            variables: [(name: "draft", value: "true"), (name: "title", value: "@notes.txt")],
            host: "gitlab.example.com"
        )

        #expect(arguments == ["api", "graphql", "--hostname", "gitlab.example.com", "-f", "query=mutation { x }", "-F", "draft=true", "-f", "title=@notes.txt"])
    }

    @Test func restWritesPassTheMethodAndFields() {
        let arguments = GlabClient.restArguments(
            endpoint: "projects/team%2Fapp/merge_requests/7/merge",
            method: "PUT",
            fields: [(name: "squash", value: "true")],
            host: "gitlab.example.com"
        )

        #expect(arguments == ["api", "--hostname", "gitlab.example.com", "-X", "PUT", "projects/team%2Fapp/merge_requests/7/merge", "-f", "squash=true"])
    }

    @Test func aPagedReadAsksForEveryPage() {
        #expect(GlabClient.pagedArguments(endpoint: "projects/team%2Fapp/members/all?per_page=100", host: "gitlab.example.com") == ["api", "--hostname", "gitlab.example.com", "--paginate", "projects/team%2Fapp/members/all?per_page=100"])
    }

    @Test func hostAndProjectComeFromTheCodeHost() throws {
        #expect(try GlabClient.host(of: .gitLabSample) == "gitlab.example.com")
        #expect(GlabClient.projectPath(of: .gitLabSample) == "team/app")
        #expect(throws: PullRequestError.noCodeHost) {
            try GlabClient.host(of: .gitHubSample)
        }
    }
}
