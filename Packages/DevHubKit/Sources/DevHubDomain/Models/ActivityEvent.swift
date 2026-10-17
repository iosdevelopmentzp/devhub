import Foundation

package struct ActivityEvent: Identifiable, Hashable, Sendable {
    package enum Outcome: Hashable, Sendable {
        case success
        case failure
        case info
    }

    package let id: UUID
    package var title: String
    package var detail: String
    package var date: Date
    package var outcome: Outcome

    package init(id: UUID, title: String, detail: String, date: Date, outcome: Outcome) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.outcome = outcome
    }
}
