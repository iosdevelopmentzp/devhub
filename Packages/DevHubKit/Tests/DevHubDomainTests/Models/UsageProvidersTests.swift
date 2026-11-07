import Testing
@testable import DevHubDomain

@Suite struct UsageProvidersTests {
    @Test func eachChoiceNamesItsProviders() {
        #expect(UsageProviders.all.includesClaude && UsageProviders.all.includesCopilot)
        #expect(UsageProviders.claude.includesClaude && UsageProviders.claude.includesCopilot == false)
        #expect(UsageProviders.copilot.includesCopilot && UsageProviders.copilot.includesClaude == false)
        #expect(UsageProviders.none.includesClaude == false && UsageProviders.none.includesCopilot == false)
    }
}
