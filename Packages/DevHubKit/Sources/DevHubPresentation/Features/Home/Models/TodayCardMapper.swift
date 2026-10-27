import Foundation
import DevHubDomain
import DevHubUI

enum TodayCardMapper {
    static let emptyTitle = "Nothing waits for you"

    static func items(
        reviewCount: Int,
        openRequests: [PullRequestSummary],
        username: String?,
        worktrees: [Worktree],
        simulators: [Simulator],
        words: CodeHostWords
    ) -> [TodayItemModel] {
        [
            reviewItem(reviewCount, words: words),
            failedItem(openRequests, username: username, words: words),
            worktreesItem(worktrees),
            simulatorsItem(simulators),
        ].compactMap { $0 }
    }

    private static func reviewItem(_ count: Int, words: CodeHostWords) -> TodayItemModel? {
        guard count > 0 else { return nil }
        return TodayItemModel(
            id: "review",
            icon: "eye.fill",
            tint: .blue,
            title: "\(CountText.count(count, words.request, words.requests)) \(count == 1 ? "waits" : "wait") for your review",
            detail: nil,
            target: .pullRequests(.reviewing)
        )
    }

    private static func failedItem(_ requests: [PullRequestSummary], username: String?, words: CodeHostWords) -> TodayItemModel? {
        guard let username else { return nil }
        let failed = requests
            .filter { $0.author == username && $0.pipeline?.status == .failed }
            .sorted { $0.iid > $1.iid }
        guard let first = failed.first else { return nil }
        if failed.count == 1 {
            return TodayItemModel(
                id: "failed",
                icon: "xmark.octagon.fill",
                tint: .red,
                title: "\(words.reference(first.iid)) \(first.title)",
                detail: "Your \(words.request): \(words.checks) failed",
                target: .pullRequest(first.iid)
            )
        }
        return TodayItemModel(
            id: "failed",
            icon: "xmark.octagon.fill",
            tint: .red,
            title: "\(failed.count) of your \(words.requests): \(words.checks) failed",
            detail: failed.prefix(3).map { words.reference($0.iid) }.joined(separator: ", "),
            target: .pullRequests(.mine)
        )
    }

    private static func worktreesItem(_ worktrees: [Worktree]) -> TodayItemModel? {
        let finished = worktrees.filter(WorktreeCleanupPolicy.isSafeToClean)
        guard finished.isEmpty == false else { return nil }
        return TodayItemModel(
            id: "worktrees",
            icon: "checkmark.rectangle.stack.fill",
            tint: .purple,
            title: "\(CountText.count(finished.count, "finished worktree")) can be cleaned up",
            detail: finished.prefix(3).map { $0.branch ?? $0.path }.joined(separator: ", "),
            target: .worktrees
        )
    }

    private static func simulatorsItem(_ simulators: [Simulator]) -> TodayItemModel? {
        let booted = simulators.filter { $0.state == .booted }
        guard booted.isEmpty == false else { return nil }
        return TodayItemModel(
            id: "simulators",
            icon: "iphone",
            tint: .green,
            title: "\(CountText.count(booted.count, "simulator")) booted",
            detail: booted.prefix(3).map(\.name).joined(separator: ", "),
            target: .simulators
        )
    }
}
