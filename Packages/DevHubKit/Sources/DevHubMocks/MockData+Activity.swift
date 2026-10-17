import Foundation
import DevHubDomain

extension MockData {
    package static let recentEvents: [ActivityEvent] = [
        ActivityEvent(id: UUID(), title: "Build succeeded", detail: "ExampleApp · Debug · 1m 42s", date: ago(minutes: 12), outcome: .success),
        ActivityEvent(id: UUID(), title: "Ran Rebase onto dev", detail: "rebase-dev.sh", date: ago(hours: 2), outcome: .success),
        ActivityEvent(id: UUID(), title: "Build failed", detail: "ExampleApp · Debug · GiftsBanner.swift:42", date: ago(hours: 3), outcome: .failure),
        ActivityEvent(id: UUID(), title: "Removed worktree", detail: "ABC-2470-profileBadges", date: ago(days: 1), outcome: .info)
    ]
}
