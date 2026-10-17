import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MockRuleMatcherTests {

    @Test func exactPathAndMethodMatch() {
        let rule = MockRuleFixture.respond(method: "GET", path: "/v1/settings/list")

        #expect(MockRuleMatcher.match(method: "GET", path: "/v1/settings/list", query: nil, in: [rule]) == rule)
        #expect(MockRuleMatcher.match(method: "get", path: "/v1/settings/list/", query: nil, in: [rule]) == rule)
        #expect(MockRuleMatcher.match(method: "POST", path: "/v1/settings/list", query: nil, in: [rule]) == nil)
        #expect(MockRuleMatcher.match(method: "GET", path: "/v1/settings", query: nil, in: [rule]) == nil)
    }

    @Test func nilOrEmptyMethodMatchesAnyMethod() {
        let any = MockRuleFixture.respond(method: nil, path: "/v1/x")
        let empty = MockRuleFixture.respond(method: " ", path: "/v1/y")

        #expect(MockRuleMatcher.matches(any, method: "DELETE", path: "/v1/x", query: nil))
        #expect(MockRuleMatcher.matches(empty, method: "PUT", path: "/v1/y", query: nil))
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

        #expect(MockRuleMatcher.match(method: "GET", path: "/v1/x", query: nil, in: [disabled, first, second]) == first)
        #expect(MockRuleMatcher.match(method: "GET", path: "/v1/x", query: nil, in: [disabled]) == nil)
    }
}
