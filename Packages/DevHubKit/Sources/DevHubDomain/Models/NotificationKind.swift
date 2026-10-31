import Foundation

package enum NotificationKind: String, CaseIterable, Hashable, Codable, Sendable {
    case build
    case tests
    case reviewRequests
    case requestReviews
    case requestChecks
    case requestComments
    case requestClosed
    case scripts

    package var showsWhilePanelIsOpen: Bool {
        self == .scripts
    }
}
