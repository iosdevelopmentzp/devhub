import Foundation

nonisolated struct ActivityEvent: Identifiable, Hashable, Sendable {
    enum Outcome: Hashable, Sendable {
        case success
        case failure
        case info
    }

    let id: UUID
    let date: Date
    var title: String
    var detail: String
    var outcome: Outcome
}
