import Foundation
import DevHubUI

struct UpdateIndicatorModel: Equatable {
    var text: String
    var icon: String
    var tint: Tint
    var isRunning: Bool
    var hint: String
    var canOpen: Bool
    var title: String
    var commits: [UpdateCommitRowModel]
    var failure: String?
    var showsLog: Bool
    var actionTitle: String?

    static let preview = UpdateIndicatorModel(
        text: "Update available · 2",
        icon: "arrow.down.circle.fill",
        tint: .blue,
        isRunning: false,
        hint: UpdateIndicatorMapper.availableHint,
        canOpen: true,
        title: "2 new commits on origin/main",
        commits: [
            .preview,
            UpdateCommitRowModel(id: "d4e5f6a", hash: "d4e5f6a", subject: "fix(operations): a strip of rows instead of floating cards"),
        ],
        failure: nil,
        showsLog: false,
        actionTitle: "Update Now"
    )

    static let previewRunning = UpdateIndicatorModel(
        text: "Building · 1:20",
        icon: "arrow.down.circle",
        tint: .secondary,
        isRunning: true,
        hint: UpdateIndicatorMapper.runningHint,
        canOpen: false,
        title: "Building",
        commits: [],
        failure: nil,
        showsLog: false,
        actionTitle: nil
    )

    static let previewFailed = UpdateIndicatorModel(
        text: "Update failed",
        icon: "exclamationmark.triangle.fill",
        tint: .orange,
        isRunning: false,
        hint: UpdateIndicatorMapper.failedHint,
        canOpen: true,
        title: "Update failed",
        commits: [],
        failure: "The build or the install failed. See update.log",
        showsLog: true,
        actionTitle: "Try Again"
    )
}
