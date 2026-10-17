import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ActivityLog {
    private(set) var events: [ActivityEvent]

    init(events: [ActivityEvent]) {
        self.events = events
    }

    func log(_ title: String, detail: String, outcome: ActivityEvent.Outcome) {
        events.insert(ActivityEvent(id: UUID(), title: title, detail: detail, date: .now, outcome: outcome), at: 0)
        if events.count > 8 {
            events.removeLast(events.count - 8)
        }
    }

    func clear() {
        events.removeAll()
    }
}
