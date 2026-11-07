import Foundation

package enum NotificationKind: String, CaseIterable, Hashable, Codable, Sendable {
    case build
    case tests
    case reviewRequests
    case reviewReminders
    case requestReviews
    case requestChecks
    case requestChecksPassed
    case requestApprovals
    case baseBranchChecks
    case requestComments
    case requestClosed
    case watched
    case inbox
    case crashes
    case scripts
    case utilities

    package var showsWhilePanelIsOpen: Bool {
        self == .scripts
    }
}
