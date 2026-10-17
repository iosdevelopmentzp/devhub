import Foundation
import DevHubDomain

struct MergeRequestRowContext {
    var username: String?
    var scope: MergeRequestScope
    var seenAt: Date?
    var now: Date
    var isMainCheckoutClean: Bool
    var ticketURLTemplate: String
}
