import Foundation
import DevHubDomain
import DevHubUI

enum ActivityRowMapper {

    static func model(for event: ActivityEvent, words: CodeHostWords) -> ActivityRowModel {
        ActivityRowModel(
            id: event.id,
            title: event.title,
            detail: event.detail,
            dateText: event.date.relativeDescription,
            dotTint: dotTint(for: event.outcome),
            dotOpacity: event.outcome == .info ? 0.5 : 1,
            kindTitle: event.kind.map { NotificationKindText.shortTitle(for: $0, words: words) },
            target: event.target,
            openHint: event.target.map { openHint(for: $0, words: words) }
        )
    }

    static func openHint(for target: ActivityTarget, words: CodeHostWords) -> String {
        switch target {
        case .pullRequest(let iid): "Open \(words.reference(iid))"
        case .reviewQueue: "Open the \(words.requests) that wait for your review"
        case .worktree: "Open the Worktrees tab"
        case .build: "Open the run bar in the Simulators tab"
        case .inbox: "Open the Inbox"
        }
    }

    private static func dotTint(for outcome: ActivityEvent.Outcome) -> Tint {
        switch outcome {
        case .success: .green
        case .failure: .red
        case .info: .secondary
        }
    }
}
