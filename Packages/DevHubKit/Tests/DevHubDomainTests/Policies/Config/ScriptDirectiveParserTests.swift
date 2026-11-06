import Testing
@testable import DevHubDomain

@Suite struct ScriptDirectiveParserTests {
    @Test func aPlainLineIsPlain() {
        #expect(ScriptDirectiveParser.parse("hello") == .plain)
    }

    @Test func readsEveryDirective() {
        let line = #"@devhub {"progress": "Step", "fraction": 0.5, "toast": "Done", "copy": "abc", "open": "https://example.com", "notify": "Built", "body": "ok", "refresh": ["git", "nope"], "error": "bad", "app": "/tmp/App.app"}"#

        #expect(ScriptDirectiveParser.parse(line) == .directives([
            .progress(text: "Step", fraction: 0.5),
            .toast("Done"),
            .copy("abc"),
            .open("https://example.com"),
            .notify(title: "Built", body: "ok"),
            .refresh([.git]),
            .error("bad"),
            .app("/tmp/App.app"),
        ]))
    }

    @Test func appDataIsARefreshTarget() {
        #expect(ScriptDirectiveParser.parse(#"@devhub {"refresh": ["appData"]}"#) == .directives([.refresh([.appData])]))
    }

    @Test func aViewIsDecoded() {
        let line = #"@devhub {"view": {"keyValues": [["Env", "staging"]], "rows": [{"id": "1", "title": "Row", "tags": [{"text": "ok", "tint": "green"}]}]}}"#

        guard case let .directives(directives) = ScriptDirectiveParser.parse(line), case let .view(view) = directives.first else {
            Issue.record("no view")
            return
        }
        #expect(view.pairs.map(\.0) == ["Env"])
        #expect(view.rows?.first?.tags?.first?.tint == .green)
        #expect(view.isEmpty == false)
    }

    @Test func badJSONAndBadViewsAreInvalid() {
        #expect(ScriptDirectiveParser.parse("@devhub {nope") == .invalid("The directive is not one JSON object."))
        guard case .invalid = ScriptDirectiveParser.parse(#"@devhub {"view": {"rows": [{"title": "no id"}]}}"#) else {
            Issue.record("expected invalid")
            return
        }
    }

    @Test func anUnknownKeyIsUnknown() {
        #expect(ScriptDirectiveParser.parse(#"@devhub {"other": 1}"#) == .unknown)
    }

    @Test func readsTheStateDirective() {
        let line = #"@devhub {"state": {"identity": "devhub-3f9a1c2e", "profile": "staging", "host": "api.staging.example.com", "user": " ", "version": "2.4.0", "tags": [{"text": "beta", "tint": "purple", "icon": "flask", "hint": "Beta build"}, {"text": " "}]}}"#

        #expect(ScriptDirectiveParser.parse(line) == .directives([
            .state(AppStateReport(identity: "devhub-3f9a1c2e", profile: "staging", host: "api.staging.example.com", user: nil, version: "2.4.0", tags: [ScriptViewTag(text: "beta", tint: .purple, icon: "flask", hint: "Beta build")]))
        ]))
    }

    @Test func badStateTagsAreInvalid() {
        #expect(ScriptDirectiveParser.parse(#"@devhub {"state": {"tags": "beta"}}"#) == .invalid("The state tags are not a JSON list."))
        guard case .invalid = ScriptDirectiveParser.parse(#"@devhub {"state": {"tags": [{"tint": "green"}]}}"#) else {
            Issue.record("expected invalid")
            return
        }
    }
}
