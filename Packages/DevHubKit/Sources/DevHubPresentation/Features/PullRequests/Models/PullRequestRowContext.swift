import Foundation
import DevHubDomain

struct PullRequestRowContext {
    var username: String?
    var scope: PullRequestScope
    var seenAt: Date?
    var now: Date
    var isMainCheckoutClean: Bool
    var ticket: TicketSettings
}
