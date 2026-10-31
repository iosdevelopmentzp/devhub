import Foundation
import DevHubDomain

extension MockData {
    package static let recentEvents: [ActivityEvent] = [
        ActivityEvent(id: UUID(), title: "Built ExampleApp", detail: "Debug · example-app", date: ago(minutes: 12), outcome: .success, kind: .build, target: .build),
        ActivityEvent(id: UUID(), title: "#12 approved by alex", detail: "ABC-123: Login screen", date: ago(minutes: 40), outcome: .success, kind: .requestReviews, target: .pullRequest(iid: 12)),
        ActivityEvent(id: UUID(), title: "Ran Rebase onto dev", detail: "rebase-dev.sh", date: ago(hours: 2), outcome: .success),
        ActivityEvent(id: UUID(), title: "Tests failed: feature/ABC-123-login", detail: "41 passed · 2 failed · ExampleApp · iPhone 17", date: ago(hours: 3), outcome: .failure, kind: .tests, target: .worktree(path: "/Users/alex/Projects/example-app/.worktrees/ABC-123-login")),
        ActivityEvent(id: UUID(), title: "2 requests wait for your review", detail: "", date: ago(hours: 5), outcome: .info, kind: .reviewRequests, target: .reviewQueue),
        ActivityEvent(id: UUID(), title: "Build failed", detail: "ExampleApp · Debug · GiftsBanner.swift:42", date: ago(days: 1), outcome: .failure, kind: .build, target: .build),
        ActivityEvent(id: UUID(), title: "Checks failed on #9", detail: "ABC-120: Profile badges", date: ago(days: 1), outcome: .failure, kind: .requestChecks, target: .pullRequest(iid: 9)),
        ActivityEvent(id: UUID(), title: "Removed worktree", detail: "ABC-120-profileBadges", date: ago(days: 2), outcome: .info),
        ActivityEvent(id: UUID(), title: "#9 merged", detail: "ABC-120: Profile badges", date: ago(days: 2), outcome: .success, kind: .requestClosed, target: .pullRequest(iid: 9)),
        ActivityEvent(id: UUID(), title: "Resources ready", detail: "sync-resources.sh", date: ago(days: 3), outcome: .info, kind: .scripts)
    ]
}
