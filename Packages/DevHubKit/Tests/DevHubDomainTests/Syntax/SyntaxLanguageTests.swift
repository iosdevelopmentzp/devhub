import Testing
@testable import DevHubDomain

@Suite struct SyntaxLanguageTests {
    @Test func theLanguageComesFromTheFileExtension() {
        #expect(SyntaxLanguage.language(forPath: "Sources/App/Store.swift") == .swift)
        #expect(SyntaxLanguage.language(forPath: "Sources/App/Store.SWIFT") == .swift)
        #expect(SyntaxLanguage.language(forPath: "Sources/App/Store.m") == nil)
        #expect(SyntaxLanguage.language(forPath: "Package.resolved") == nil)
        #expect(SyntaxLanguage.language(forPath: "swift") == nil)
    }
}
