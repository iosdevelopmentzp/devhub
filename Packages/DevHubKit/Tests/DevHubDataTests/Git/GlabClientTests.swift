import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabClientTests {
    @Test func graphqlPassesTheQueryAndVariablesAsFields() {
        let arguments = GlabClient.graphqlArguments(
            query: "query { x }",
            variables: [(name: "path", value: "team/app"), (name: "iid", value: "7")],
            host: "gitlab.example.com"
        )

        #expect(arguments == ["api", "graphql", "--hostname", "gitlab.example.com", "-f", "query=query { x }", "-f", "path=team/app", "-f", "iid=7"])
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

    @Test func hostAndProjectComeFromTheCodeHost() throws {
        #expect(try GlabClient.host(of: .gitLabSample) == "gitlab.example.com")
        #expect(GlabClient.projectPath(of: .gitLabSample) == "team/app")
        #expect(throws: MergeRequestError.noCodeHost) {
            try GlabClient.host(of: .gitHubSample)
        }
    }
}
