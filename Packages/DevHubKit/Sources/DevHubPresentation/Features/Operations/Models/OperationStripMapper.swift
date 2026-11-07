import Foundation
import DevHubDomain
import DevHubUI

enum OperationStripMapper {
    static let rowLimit = 3

    static func model(for cards: [OperationCardModel], expandedID: OperationRecord.ID?) -> OperationsStripModel {
        let shown = cards.prefix(rowLimit)
        let hidden = cards.count - shown.count
        return OperationsStripModel(
            rows: shown.map { row(for: $0, isExpanded: $0.id == expandedID) },
            moreText: hidden > 0 ? "\(hidden) more in the footer list" : nil
        )
    }

    static func row(for card: OperationCardModel, isExpanded: Bool) -> OperationStripModel {
        let canExpand = card.steps.isEmpty == false || card.message != nil || card.digest.isEmpty == false || card.hasFullOutput
        return OperationStripModel(
            id: card.id,
            title: card.title,
            icon: card.icon,
            tint: card.tint,
            isRunning: card.isRunning,
            startedAt: card.startedAt,
            detail: card.detail,
            summary: card.message ?? card.liveLine,
            fraction: card.fraction,
            canRetry: card.canRetry,
            canStop: card.canStop,
            canDismiss: card.canDismiss,
            canExpand: canExpand,
            isExpanded: isExpanded,
            expandHint: isExpanded ? "Hide the card of this operation" : (card.isRunning ? "Show the steps of this operation" : "Show the steps and the lines that explain the failure"),
            hidesSoon: card.hidesSoon
        )
    }
}
