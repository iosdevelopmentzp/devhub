import Foundation
import DevHubDomain
import DevHubUI

enum UsageProviderMapper {

    static func models(
        claude: ClaudeUsage?,
        claudeError: String?,
        copilot: CopilotUsage?,
        copilotError: String?,
        providers: UsageProviders,
        now: Date
    ) -> [UsageProviderModel] {
        var models: [UsageProviderModel] = []
        if providers.includesClaude {
            models.append(UsageProviderModel(
                id: "claude",
                title: "Claude",
                summary: claude.map { UsageSummaryMapper.model(for: $0, now: now) },
                error: claudeError,
                loadingText: "Loading Claude usage…",
                unavailableText: "Claude usage unavailable",
                usageURL: URL(string: "https://claude.ai/settings/usage")
            ))
        }
        if providers.includesCopilot, providers == .copilot || copilot != nil || copilotError != nil {
            models.append(UsageProviderModel(
                id: "copilot",
                title: "Copilot",
                summary: copilot.map { UsageSummaryMapper.model(for: $0, now: now) },
                error: copilotError,
                loadingText: "Loading Copilot usage…",
                unavailableText: "Copilot usage unavailable",
                usageURL: URL(string: "https://github.com/settings/copilot")
            ))
        }
        return models
    }
}
