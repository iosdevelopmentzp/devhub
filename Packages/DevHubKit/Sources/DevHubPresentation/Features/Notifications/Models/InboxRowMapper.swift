import Foundation
import DevHubDomain
import DevHubUI

enum InboxRowMapper {

    static func models(for items: [InboxItem], busyIDs: Set<String>, query: String, words: CodeHostWords) -> [InboxRowModel] {
        items
            .map { model(for: $0, isBusy: busyIDs.contains($0.id), words: words) }
            .filter { matches($0, query: query) }
    }

    static func model(for item: InboxItem, isBusy: Bool, words: CodeHostWords) -> InboxRowModel {
        let pullRequestIID: Int? = if case .pullRequest(let iid) = item.target { iid } else { nil }
        return InboxRowModel(
            id: item.id,
            icon: icon(for: item.kind),
            iconTint: tint(for: item.kind),
            iconHint: InboxItemText.kindTitle(for: item.kind, words: words),
            title: InboxItemText.title(for: item, words: words),
            detail: [item.title, item.excerpt].compactMap { $0 }.filter { $0.isEmpty == false }.joined(separator: " · "),
            dateText: item.updatedAt?.relativeDescription,
            webURL: item.webURL,
            pullRequestIID: pullRequestIID,
            openHint: pullRequestIID.map { "Open \(words.reference($0)) in DevHub" },
            doneHint: words.kind == .github ? "Mark as done on GitHub: the thread leaves the Inbox" : "Mark as done on \(words.name): the to-do leaves the Inbox",
            isBusy: isBusy
        )
    }

    private static func matches(_ model: InboxRowModel, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { return true }
        return model.title.localizedCaseInsensitiveContains(trimmed) || model.detail.localizedCaseInsensitiveContains(trimmed)
    }

    private static func icon(for kind: InboxItem.Kind) -> String {
        switch kind {
        case .mention: "at"
        case .reviewRequested: "eye"
        case .assigned: "person"
        case .comment: "bubble.left"
        case .approvalRequired: "checkmark.seal"
        case .checksFailed: "xmark.octagon"
        case .other: "tray"
        }
    }

    private static func tint(for kind: InboxItem.Kind) -> Tint {
        switch kind {
        case .mention: .purple
        case .reviewRequested: .indigo
        case .assigned: .blue
        case .comment: .secondary
        case .approvalRequired: .orange
        case .checksFailed: .red
        case .other: .gray
        }
    }
}
