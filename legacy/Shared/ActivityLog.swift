import Foundation
import Observation

@MainActor
@Observable
final class ActivityLog {
    private(set) var events: [ActivityEvent] = []

    func log(_ title: String, detail: String, outcome: ActivityEvent.Outcome) {
        let event = ActivityEvent(id: UUID(), date: Date(), title: title, detail: detail, outcome: outcome)
        events.insert(event, at: 0)
        if events.count > 100 {
            events.removeLast(events.count - 100)
        }
    }

    func clear() {
        events.removeAll()
    }
}
