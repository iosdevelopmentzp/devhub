import Foundation
import DevHubDomain

enum InboxItemText {

    static func title(for item: InboxItem, words: CodeHostWords) -> String {
        let reference = reference(for: item, words: words)
        switch item.kind {
        case .mention:
            return item.actor.map { "\($0) mentioned you in \(reference)" } ?? "You were mentioned in \(reference)"
        case .reviewRequested:
            return item.actor.map { "\($0) asked for your review on \(reference)" } ?? "Your review is requested on \(reference)"
        case .assigned:
            return item.actor.map { "\($0) assigned you \(reference)" } ?? "You were assigned \(reference)"
        case .comment:
            return item.actor.map { "\($0) commented on \(reference)" } ?? "New comment on \(reference)"
        case .approvalRequired:
            return item.actor.map { "\($0) needs your approval on \(reference)" } ?? "Your approval is needed on \(reference)"
        case .checksFailed:
            return "\(words.checksTitle) failed on \(reference)"
        case .other(let reason):
            return item.actor.map { "\($0): \(reason) on \(reference)" } ?? "\(reason.prefix(1).uppercased() + reason.dropFirst()) on \(reference)"
        }
    }

    static func kindTitle(for kind: InboxItem.Kind, words: CodeHostWords) -> String {
        switch kind {
        case .mention: "Mention"
        case .reviewRequested: "Review requested"
        case .assigned: "Assigned"
        case .comment: "Comment"
        case .approvalRequired: "Approval needed"
        case .checksFailed: "\(words.checksTitle) failed"
        case .other(let reason): reason.prefix(1).uppercased() + reason.dropFirst()
        }
    }

    static func reference(for item: InboxItem, words: CodeHostWords) -> String {
        switch item.target {
        case .pullRequest(let iid): words.reference(iid)
        case .issue(let iid): "issue #\(iid)"
        case .other: item.title
        }
    }

    static func target(for item: InboxItem) -> ActivityTarget {
        if case .pullRequest(let iid) = item.target {
            return .pullRequest(iid: iid)
        }
        return .inbox
    }
}
