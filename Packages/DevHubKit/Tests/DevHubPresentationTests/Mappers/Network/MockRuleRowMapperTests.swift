import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct MockRuleRowMapperTests {

    @Test func mapsARespondRule() {
        let rule = MockRule(id: UUID(), isEnabled: true, method: "post", pathPattern: "/v1/chat", query: "a=1", action: .respond(MockResponse(status: 201, headers: [], body: "", delay: 0)))

        let model = MockRuleRowMapper.model(for: rule, isEditing: true)

        #expect(model.method == "POST")
        #expect(model.methodTint == .green)
        #expect(model.path == "/v1/chat?a=1")
        #expect(model.summary == "Respond 201")
        #expect(model.summaryTint == .purple)
        #expect(model.isEnabled)
        #expect(model.isEditing)
    }

    @Test func anyMethodAndDisabledRuleAreGray() {
        let rule = MockRule(id: UUID(), isEnabled: false, method: nil, pathPattern: "/v1/**", query: nil, action: .patch(MockPatch(operations: [JSONPatchOperation(keyPath: "a", value: "1")], delay: 0.3)))

        let model = MockRuleRowMapper.model(for: rule, isEditing: false)

        #expect(model.method == "ANY")
        #expect(model.methodTint == .gray)
        #expect(model.summary == "Patch 1 key · 300 ms delay")
        #expect(model.summaryTint == .secondary)
    }

    @Test func respondSummaryMentionsTheBodySize() {
        let summary = MockRuleRowMapper.summary(of: .respond(MockResponse(status: 200, headers: [], body: "{}", delay: 0)))

        #expect(summary.hasPrefix("Respond 200 · "))
    }

    @Test func aGraphQLRuleShowsItsOperationAfterThePath() {
        var rule = MockRuleFactory.newRule(id: UUID())
        rule.pathPattern = "/graphql"
        rule.operationName = "GetProfile"

        #expect(MockRuleRowMapper.model(for: rule, isEditing: false).path == "/graphql · GetProfile")
    }
}
