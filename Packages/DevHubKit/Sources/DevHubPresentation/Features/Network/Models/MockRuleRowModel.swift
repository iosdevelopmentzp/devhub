import Foundation
import DevHubDomain
import DevHubUI

struct MockRuleRowModel: Identifiable, Equatable {
    let id: MockRule.ID
    var method: String
    var methodTint: Tint
    var path: String
    var summary: String
    var summaryTint: Tint
    var isEnabled: Bool
    var isEditing: Bool

    static let preview = MockRuleRowModel(
        id: UUID(),
        method: "GET",
        methodTint: .blue,
        path: "/v1/settings/list",
        summary: "Respond 200 · 52 B",
        summaryTint: .purple,
        isEnabled: true,
        isEditing: false
    )
}
