import Foundation

package enum NotificationKind: String, CaseIterable, Hashable, Codable, Sendable {
    case build
    case tests
    case reviewRequests
    case requestReviews
    case requestChecks
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
