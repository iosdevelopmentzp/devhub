import Foundation
import DevHubDomain
import DevHubUI

enum UpdateIndicatorMapper {
    static let availableHint = "New commits on the remote branch. Click to see them and update"
    static let runningHint = "DevHub is updating itself. It quits for a few seconds when the new build is installed, then opens again"
    static let failedHint = "The update failed. Click for the log and Try Again"

    static func model(for state: UpdateStore.State, remoteBranch: String, now: Date) -> UpdateIndicatorModel? {
        switch state {
        case .idle:
            return nil
        case .available(let commits):
            return UpdateIndicatorModel(
                text: "Update available · \(commits.count)",
                icon: "arrow.down.circle.fill",
                tint: .blue,
                isRunning: false,
                hint: availableHint,
                canOpen: true,
                title: "\(CountText.count(commits.count, "new commit")) on \(remoteBranch)",
                commits: commits.map { UpdateCommitRowModel(id: $0.hash, hash: $0.hash, subject: $0.subject) },
                failure: nil,
                showsLog: false,
                actionTitle: "Update Now"
            )
        case .running(let phase, let startedAt):
            return UpdateIndicatorModel(
                text: "\(phase.title) · \(ElapsedTime.text(now.timeIntervalSince(startedAt)))",
                icon: "arrow.down.circle",
                tint: .secondary,
                isRunning: true,
                hint: runningHint,
                canOpen: false,
                title: phase.title,
                commits: [],
                failure: nil,
                showsLog: false,
                actionTitle: nil
            )
        case .failed(let message):
            return UpdateIndicatorModel(
                text: "Update failed",
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                isRunning: false,
                hint: failedHint,
                canOpen: true,
                title: "Update failed",
                commits: [],
                failure: message,
                showsLog: true,
                actionTitle: "Try Again"
            )
        }
    }
}
