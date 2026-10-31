import Foundation
import DevHubDomain
import DevHubUI

struct OperationCardModel: Identifiable, Equatable {
    struct Step: Identifiable, Equatable {
        let id: UUID
        var command: String
        var icon: String
        var tint: Tint
        var isRunning: Bool
        var duration: String?
    }

    let id: OperationRecord.ID
    var title: String
    var icon: String
    var tint: Tint
    var isRunning: Bool
    var startedAt: Date
    var detail: String?
    var fraction: Double?
    var steps: [Step]
    var hiddenStepCount: Int
    var liveLine: String?
    var message: String?
    var failedStep: String?
    var digest: [String]
    var fullOutput: String?
    var hasFullOutput: Bool
    var isOutputOpen: Bool
    var canRetry: Bool
    var canStop: Bool
    var canDismiss: Bool
    var hidesSoon: Bool
    var errorText: String?

    static let preview = OperationCardModel(
        id: UUID(),
        title: "Push feature/ABC-123-short-title failed",
        icon: "xmark.octagon.fill",
        tint: .red,
        isRunning: false,
        startedAt: Date(),
        detail: "1.2 s",
        fraction: nil,
        steps: [
            Step(id: UUID(), command: "git push origin feature/ABC-123-short-title", icon: "xmark.circle.fill", tint: .red, isRunning: false, duration: "1.1 s")
        ],
        hiddenStepCount: 0,
        liveLine: nil,
        message: "The remote has commits that you do not have.",
        failedStep: "git push origin feature/ABC-123-short-title · exit 1",
        digest: [
            "! [rejected] feature/ABC-123-short-title -> feature/ABC-123-short-title (fetch first)",
            "error: failed to push some refs to 'github.com/example/app'",
            "hint: Updates were rejected because the remote contains work that you do not have locally."
        ],
        fullOutput: nil,
        hasFullOutput: true,
        isOutputOpen: false,
        canRetry: true,
        canStop: false,
        canDismiss: true,
        hidesSoon: false,
        errorText: "Push failed"
    )
}
