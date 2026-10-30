import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct UsageProviderMapperTests {
    private let copilot = CopilotUsage(plan: nil, limits: [], updatedAt: UsageFixture.now)

    @Test func copilotIsHiddenWithoutUsageOrError() {
        let models = UsageProviderMapper.models(claude: UsageFixture.usage, claudeError: nil, copilot: nil, copilotError: nil, providers: .all, now: UsageFixture.now)

        #expect(models.map(\.id) == ["claude"])
        #expect(models.first?.summary?.meters.count == 2)
        #expect(models.first?.usageURL == URL(string: "https://claude.ai/settings/usage"))
    }

    @Test func copilotShowsItsUsageOrItsError() {
        let withUsage = UsageProviderMapper.models(claude: nil, claudeError: "no login", copilot: copilot, copilotError: nil, providers: .all, now: UsageFixture.now)
        let withError = UsageProviderMapper.models(claude: nil, claudeError: nil, copilot: nil, copilotError: "rejected", providers: .all, now: UsageFixture.now)

        #expect(withUsage.map(\.id) == ["claude", "copilot"])
        #expect(withUsage.first?.error == "no login")
        #expect(withUsage.last?.summary?.note == "No premium request limit")
        #expect(withUsage.last?.summary?.planTag.text == "Copilot")
        #expect(withUsage.last?.usageURL == URL(string: "https://github.com/settings/copilot"))
        #expect(withError.last?.summary == nil)
        #expect(withError.last?.error == "rejected")
        #expect(withError.last?.unavailableText == "Copilot usage unavailable")
    }

    @Test func claudeOnlyHidesCopilotEvenWithUsage() {
        let models = UsageProviderMapper.models(claude: UsageFixture.usage, claudeError: nil, copilot: copilot, copilotError: "rejected", providers: .claude, now: UsageFixture.now)

        #expect(models.map(\.id) == ["claude"])
    }

    @Test func copilotOnlyShowsCopilotEvenWhileLoading() {
        let models = UsageProviderMapper.models(claude: UsageFixture.usage, claudeError: nil, copilot: nil, copilotError: nil, providers: .copilot, now: UsageFixture.now)

        #expect(models.map(\.id) == ["copilot"])
        #expect(models.first?.summary == nil)
        #expect(models.first?.loadingText == "Loading Copilot usage…")
    }
}
