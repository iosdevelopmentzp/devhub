import Foundation
import DevHubDomain

enum NotificationFilter: Hashable {
    case all
    case kind(NotificationKind)
    case other

    func includes(_ event: ActivityEvent) -> Bool {
        switch self {
        case .all: true
        case .kind(let kind): event.kind == kind
        case .other: event.kind == nil
        }
    }
}
