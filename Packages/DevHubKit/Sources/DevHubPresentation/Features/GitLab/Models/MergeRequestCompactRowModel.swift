import Foundation
import DevHubDomain
import DevHubUI

struct MergeRequestCompactRowModel: Identifiable, Equatable {
    let id: MergeRequestSummary.ID
    var reference: String
    var title: String
    var icon: String
    var iconTint: Tint
    var iconHint: String
    var isNew: Bool
    var signals: [TagModel]
    var author: String
    var authorTint: Tint?
    var dateText: String?
    var webURL: URL?
    var linkText: String

    static let preview = MergeRequestCompactRowModel(
        id: 1842,
        reference: "!1842",
        title: "ABC-2324: Paid call payment",
        icon: "arrow.triangle.pull",
        iconTint: .blue,
        iconHint: "Open",
        isNew: true,
        signals: [
            .icon("checkmark.circle.fill", tint: .green, hint: "Pipeline passed"),
            TagModel("1", tint: .secondary, systemImage: "checkmark.seal", hint: "Approved by lee"),
            TagModel("2", tint: .secondary, systemImage: "bubble.left.and.bubble.right", hint: "2 open threads"),
        ],
        author: "sam",
        authorTint: nil,
        dateText: "2 hr. ago",
        webURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/1842"),
        linkText: "!1842 ABC-2324: Paid call payment"
    )
}
