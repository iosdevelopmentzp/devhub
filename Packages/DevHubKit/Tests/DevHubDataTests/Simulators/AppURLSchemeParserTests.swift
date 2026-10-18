import Testing
@testable import DevHubData

@Suite struct AppURLSchemeParserTests {
    @Test func readsTheSchemesOfEveryURLTypeOnce() {
        let info: [String: Any] = [
            "CFBundleIdentifier": "com.example.app",
            "CFBundleURLTypes": [
                ["CFBundleURLName": "main", "CFBundleURLSchemes": ["myapp", "myapp-chat"]],
                ["CFBundleURLSchemes": ["myapp", " "]],
                ["CFBundleURLName": "no schemes"]
            ]
        ]

        #expect(AppURLSchemeParser.schemes(in: info) == ["myapp", "myapp-chat"])
    }

    @Test func noInfoMeansNoSchemes() {
        #expect(AppURLSchemeParser.schemes(in: nil).isEmpty)
        #expect(AppURLSchemeParser.schemes(in: ["CFBundleIdentifier": "com.example.app"]).isEmpty)
    }
}
