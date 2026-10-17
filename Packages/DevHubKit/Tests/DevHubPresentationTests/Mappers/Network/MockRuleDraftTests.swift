import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct MockRuleDraftTests {
    private let id = UUID()

    @Test func respondRuleRoundTrips() throws {
        let rule = MockRule(
            id: id,
            isEnabled: false,
            method: "GET",
            pathPattern: "/v1/settings/list",
            query: "lang=en",
            action: .respond(MockResponse(status: 404, headers: [HTTPHeader(name: "Content-Type", value: "application/json")], body: "{}", delay: 0.25))
        )

        let draft = MockRuleDraft(rule: rule)

        #expect(draft.delayMilliseconds == "250")
        #expect(draft.contentType == "application/json")
        #expect(try #require(draft.rule(id: id, isEnabled: false)) == rule)
    }

    @Test func patchRuleRoundTripsThroughLines() throws {
        let rule = MockRule(
            id: id,
            isEnabled: true,
            method: nil,
            pathPattern: "/v1/profile/*",
            query: nil,
            action: .patch(MockPatch(operations: [JSONPatchOperation(keyPath: "data.isVIP", value: "true"), JSONPatchOperation(keyPath: "data.banner", value: nil)], delay: 0))
        )

        let draft = MockRuleDraft(rule: rule)

        #expect(draft.method == "ANY")
        #expect(draft.patchLines == "data.isVIP = true\nremove data.banner")
        #expect(try #require(draft.rule(id: id, isEnabled: true)) == rule)
    }

    @Test func parsesPatchLines() {
        #expect(MockRuleDraft.operation(from: " data.items[0].name =  \"Bob\" ") == JSONPatchOperation(keyPath: "data.items[0].name", value: "\"Bob\""))
        #expect(MockRuleDraft.operation(from: "remove data.x") == JSONPatchOperation(keyPath: "data.x", value: nil))
        #expect(MockRuleDraft.operation(from: "data.x") == nil)
        #expect(MockRuleDraft.operation(from: "a b = 1") == nil)
        #expect(MockRuleDraft.operation(from: "a =") == nil)
    }

    @Test(arguments: [
        ("v1/x", "200", "", "", "The path must start with /."),
        ("/v1/x", "abc", "", "", "The status must be a number from 100 to 599."),
        ("/v1/x", "700", "", "", "The status must be a number from 100 to 599."),
        ("/v1/x", "200", "-5", "", "The delay must be a whole number of milliseconds."),
    ])
    func validatesTheForm(path: String, status: String, delay: String, lines: String, error: String) {
        var draft = MockRuleDraft(rule: MockRuleFactory.newRule(id: id))
        draft.path = path
        draft.status = status
        draft.delayMilliseconds = delay

        #expect(draft.validationError == error)
        #expect(draft.rule(id: id, isEnabled: true) == nil)
    }

    @Test func badPatchLineIsNamed() {
        var draft = MockRuleDraft(rule: MockRuleFactory.newRule(id: id))
        draft.kind = .patch
        draft.patchLines = "data.ok = 1\n\nnot a line"

        #expect(draft.validationError?.hasSuffix("This line is not valid: not a line") == true)
    }

    @Test func emptyContentTypeAndAnyMethodAreDropped() throws {
        var draft = MockRuleDraft(rule: MockRuleFactory.newRule(id: id))
        draft.method = "ANY"
        draft.contentType = " "

        let rule = try #require(draft.rule(id: id, isEnabled: true))

        #expect(rule.method == nil)
        #expect(rule.action == .respond(MockResponse(status: 200, headers: [], body: "{}", delay: 0)))
    }

    @Test(arguments: [
        ("{\"name”:”FakeName,”level\":1}", true),
        ("{“name”: 1}", true),
        ("[“a”]", true),
        ("{\"quote\": \"He said “hi” today\"}", false),
        ("{\"name\":\"FakeName\"}", false),
    ])
    func typographicQuotesNextToJSONPunctuationAreFound(text: String, found: Bool) {
        #expect(MockRuleDraft.hasTypographicQuotes(in: text) == found)
    }

    @Test func aJSONBodyMustParse() {
        var draft = MockRuleDraft(rule: MockRuleFactory.newRule(id: id))
        draft.contentType = "application/json"
        draft.body = "{\"a\": 1"
        #expect(draft.validationError?.hasPrefix("The body is not valid JSON: ") == true)

        draft.contentType = ""
        #expect(draft.validationError?.hasPrefix("The body is not valid JSON: ") == true)

        draft.body = "plain text"
        #expect(draft.validationError == nil)

        draft.contentType = "application/json"
        draft.body = ""
        #expect(draft.validationError == nil)

        draft.body = "{\"a\": [1, 2]}"
        #expect(draft.validationError == nil)
    }

    @Test func typographicQuotesBlockSaving() {
        var respond = MockRuleDraft(rule: MockRuleFactory.newRule(id: id))
        respond.body = "{\"name”:”FakeName\"}"
        var patch = respond
        patch.kind = .patch
        patch.patchLines = "data.name = ”FakeName”"

        #expect(respond.validationError == "The body has typographic quotes (“ ”) next to JSON punctuation. Use straight quotes (\").")
        #expect(respond.rule(id: id, isEnabled: true) == nil)
        #expect(patch.validationError == "The patch has typographic quotes (“ ”) next to JSON punctuation. Use straight quotes (\").")
    }
}
