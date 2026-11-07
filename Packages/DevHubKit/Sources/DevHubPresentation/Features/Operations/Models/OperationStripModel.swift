import Foundation
import DevHubDomain
import DevHubUI

struct OperationStripModel: Identifiable, Equatable {
    let id: OperationRecord.ID
    var title: String
    var icon: String
    var tint: Tint
    var isRunning: Bool
    var startedAt: Date
    var detail: String?
    var summary: String?
    var fraction: Double?
    var canRetry: Bool
    var canStop: Bool
    var canDismiss: Bool
    var canExpand: Bool
    var isExpanded: Bool
    var expandHint: String
    var hidesSoon: Bool

    static let preview = OperationStripModel(
        id: UUID(),
        title: "Push feature/ABC-123-short-title failed",
        icon: "xmark.octagon.fill",
        tint: .red,
        isRunning: false,
        startedAt: Date(),
        detail: "1.2 s",
        summary: "The remote has commits that you do not have.",
        fraction: nil,
        canRetry: true,
        canStop: false,
        canDismiss: true,
        canExpand: true,
        isExpanded: false,
        expandHint: "Show the steps and the lines that explain the failure",
        hidesSoon: false
    )
}
