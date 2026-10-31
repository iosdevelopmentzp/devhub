import Foundation

package struct ActivityEvent: Identifiable, Hashable, Codable, Sendable {
    package enum Outcome: Hashable, Codable, Sendable {
        case success
        case failure
        case info
    }

    package let id: UUID
    package var title: String
    package var detail: String
    package var date: Date
    package var outcome: Outcome
    package var kind: NotificationKind?
    package var target: ActivityTarget?

    package init(id: UUID, title: String, detail: String, date: Date, outcome: Outcome, kind: NotificationKind? = nil, target: ActivityTarget? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.outcome = outcome
        self.kind = kind
        self.target = target
    }
}
