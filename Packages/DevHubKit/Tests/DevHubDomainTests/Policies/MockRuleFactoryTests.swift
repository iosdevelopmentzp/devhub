import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MockRuleFactoryTests {

    @Test func respondRuleCopiesMethodPathStatusBodyAndContentType() {
        var request = NetworkRequestFixture.request(statusCode: 422, duration: 0.2, isFailure: true)
        request.method = "patch"
        request.path = "/v1/profile/settings?lang=xx"
        request.responseBody = #"{"error":"x"}"#
        request.responseHeaders = [HTTPHeader(name: "X-Id", value: "1"), HTTPHeader(name: "content-type", value: "application/json")]
        let id = UUID()

        let rule = MockRuleFactory.respondRule(from: request, id: id)

        #expect(rule == MockRule(
            id: id,
            isEnabled: true,
            method: "PATCH",
            pathPattern: "/v1/profile/settings",
            query: nil,
            action: .respond(MockResponse(status: 422, headers: [HTTPHeader(name: "content-type", value: "application/json")], body: #"{"error":"x"}"#, delay: 0))
        ))
    }

    @Test func missingStatusBecomes200AndMissingPathComesFromTheURL() {
        var request = NetworkRequestFixture.request(statusCode: nil, duration: nil, isFailure: true)
        request.path = ""
        request.method = ""

        let rule = MockRuleFactory.respondRule(from: request, id: UUID())

        #expect(rule.method == nil)
        #expect(rule.pathPattern == "/v1/x")
        #expect(rule.action == .respond(MockResponse(status: 200, headers: [], body: "", delay: 0)))
    }

    @Test func newRuleIsAnEnabledGetResponder() {
        let rule = MockRuleFactory.newRule(id: MockRuleFixture.settingsID)

        #expect(rule.isEnabled)
        #expect(rule.method == "GET")
        #expect(rule.action.delay == 0)
    }
}
