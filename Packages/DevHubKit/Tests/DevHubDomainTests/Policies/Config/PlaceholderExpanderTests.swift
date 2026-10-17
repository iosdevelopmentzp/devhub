import Testing
@testable import DevHubDomain

@Suite struct PlaceholderExpanderTests {
    @Test func replacesKnownNamesOnly() {
        #expect(PlaceholderExpander.expand("{branch} {unknown} {", values: ["branch": "main"], encodesForURL: false) == "main {unknown} {")
    }

    @Test func encodesForURLs() {
        #expect(PlaceholderExpander.expand("https://ci.example.com/{branch}", values: ["branch": "feature/ABC-1 x"], encodesForURL: true) == "https://ci.example.com/feature/ABC-1%20x")
    }
}
