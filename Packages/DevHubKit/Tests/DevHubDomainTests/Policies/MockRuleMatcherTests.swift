import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MockRuleMatcherTests {

    @Test func exactPathAndMethodMatch() {
        let rule = MockRuleFixture.respond(method: "GET", path: "/v1/settings/list")

        #expect(MockRuleMatcher.match(method: "GET", path: "/v1/settings/list", query: nil, operationNames: [], in: [rule]) == rule)
        #expect(MockRuleMatcher.match(method: "get", path: "/v1/settings/list/", query: nil, operationNames: [], in: [rule]) == rule)
        #expect(MockRuleMatcher.match(method: "POST", path: "/v1/settings/list", query: nil, operationNames: [], in: [rule]) == nil)
        #expect(MockRuleMatcher.match(method: "GET", path: "/v1/settings", query: nil, operationNames: [], in: [rule]) == nil)
    }

    @Test func nilOrEmptyMethodMatchesAnyMethod() {
        let any = MockRuleFixture.respond(method: nil, path: "/v1/x")
        let empty = MockRuleFixture.respond(method: " ", path: "/v1/y")

        #expect(MockRuleMatcher.matches(any, method: "DELETE", path: "/v1/x", query: nil, operationNames: []))
        #expect(MockRuleMatcher.matches(empty, method: "PUT", path: "/v1/y", query: nil, operationNames: []))
    }

    @Test func singleStarMatchesOneSegment() {
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/users/*/profile", path: "/v1/users/42/profile"))
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/users/*/profile", path: "/v1/users/42/x/profile") == false)
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/chat/msg-*", path: "/v1/chat/msg-40"))
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/*.json", path: "/v1/list.json"))
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/*.json", path: "/v1/list.xml") == false)
    }

    @Test func doubleStarMatchesAnyNumberOfSegments() {
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/gifts/**", path: "/v1/gifts"))
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/gifts/**", path: "/v1/gifts/catalog/popular"))
        #expect(MockRuleMatcher.pathMatches(pattern: "/**/list", path: "/v1/settings/list"))
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/gifts/**", path: "/v2/gifts/catalog") == false)
    }

    @Test func patternIgnoresAQueryInThePath() {
        #expect(MockRuleMatcher.pathMatches(pattern: "/v1/top", path: "/v1/top?period=week"))
    }

    @Test func queryPairsMustAllBePresent() {
        #expect(MockRuleMatcher.queryMatches(required: nil, query: "a=1"))
        #expect(MockRuleMatcher.queryMatches(required: "period=week", query: "period=week&page=2"))
        #expect(MockRuleMatcher.queryMatches(required: "period=week&page", query: "page=2&period=week"))
        #expect(MockRuleMatcher.queryMatches(required: "period=week", query: "period=day") == false)
        #expect(MockRuleMatcher.queryMatches(required: "page", query: nil) == false)
        #expect(MockRuleMatcher.queryMatches(required: "?name=a%20b", query: "name=a+b"))
    }

    @Test func firstEnabledMatchingRuleWins() {
        let disabled = MockRuleFixture.rule(id: UUID(), method: "GET", path: "/v1/x", query: nil, isEnabled: false)
        let first = MockRuleFixture.respond(method: nil, path: "/v1/*")
        let second = MockRuleFixture.respond(method: "GET", path: "/v1/x")

        #expect(MockRuleMatcher.match(method: "GET", path: "/v1/x", query: nil, operationNames: [], in: [disabled, first, second]) == first)
        #expect(MockRuleMatcher.match(method: "GET", path: "/v1/x", query: nil, operationNames: [], in: [disabled]) == nil)
    }

    @Test func aGraphQLRuleNeedsItsOperationName() {
        let rule = MockRule(id: UUID(), isEnabled: true, method: "POST", pathPattern: "/graphql", query: nil, action: .respond(MockResponse(status: 200, headers: [], body: "{}", delay: 0)), operationName: "Get*")

        #expect(MockRuleMatcher.matches(rule, method: "POST", path: "/graphql", query: nil, operationNames: ["GetProfile"]))
        #expect(MockRuleMatcher.matches(rule, method: "POST", path: "/graphql", query: nil, operationNames: ["UpdateProfile", "GetCart"]))
        #expect(MockRuleMatcher.matches(rule, method: "POST", path: "/graphql", query: nil, operationNames: ["UpdateProfile"]) == false)
        #expect(MockRuleMatcher.matches(rule, method: "POST", path: "/graphql", query: nil, operationNames: []) == false)
    }

    @Test func aRuleWithoutAnOperationIgnoresGraphQL() {
        #expect(MockRuleMatcher.operationMatches(required: nil, names: ["GetProfile"]))
        #expect(MockRuleMatcher.operationMatches(required: " ", names: []))
        #expect(MockRuleMatcher.operationMatches(required: "GetProfile", names: ["getprofile"]) == false)
    }
}
