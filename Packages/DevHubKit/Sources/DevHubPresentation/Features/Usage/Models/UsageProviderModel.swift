import Foundation
import DevHubDomain
import DevHubUI

struct UsageProviderModel: Identifiable, Equatable {
    let id: String
    var title: String
    var summary: UsageSummaryModel?
    var error: String?
    var loadingText: String
    var unavailableText: String
    var usageURL: URL?

    static let preview = UsageProviderModel(
        id: "claude",
        title: "Claude",
        summary: .preview,
        error: nil,
        loadingText: "Loading Claude usage…",
        unavailableText: "Claude usage unavailable",
        usageURL: URL(string: "https://claude.ai/settings/usage")
    )
}
