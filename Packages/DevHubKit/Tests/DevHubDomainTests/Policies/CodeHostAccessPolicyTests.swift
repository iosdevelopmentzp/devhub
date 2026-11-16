import DevHubDomain
import DevHubTestSupport
import Testing

@Suite struct CodeHostAccessPolicyTests {
    @Test func gitHubMissesTheNotificationsScope() {
        let access = CodeHostAccess(login: "alex", scopes: ["gist", "read:org", "repo", "workflow"])

        let missing = CodeHostAccessPolicy.missingScopes(access, kind: .github)

        #expect(missing.map(\.name) == ["notifications"])
        #expect(CodeHostAccessPolicy.fixCommand(missing: missing, host: .gitHubSample) == "gh auth refresh --hostname github.com --scopes notifications")
    }

    @Test func aWiderOrganizationScopeCountsAsReadOrg() {
        let access = CodeHostAccess(login: "alex", scopes: ["repo", "admin:org", "notifications"])

        #expect(CodeHostAccessPolicy.missingScopes(access, kind: .github).isEmpty)
    }

    @Test func unknownScopesMissNothing() {
        let access = CodeHostAccess(login: "alex", scopes: nil)

        #expect(CodeHostAccessPolicy.missingScopes(access, kind: .github).isEmpty)
        #expect(CodeHostAccessPolicy.fixCommand(missing: [], host: .gitHubSample) == nil)
    }

    @Test func gitLabNeedsTheApiScopeAndANewLogin() {
        let missing = CodeHostAccessPolicy.missingScopes(CodeHostAccess(login: "alex", scopes: ["read_api"]), kind: .gitlab)

        #expect(missing.map(\.name) == ["api"])
        #expect(CodeHostAccessPolicy.fixCommand(missing: missing, host: .gitLabSample) == "glab auth login --hostname gitlab.example.com")
    }
}
