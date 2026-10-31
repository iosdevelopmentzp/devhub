import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ActivityLog {
    static let homeLimit = 8

    private(set) var events: [ActivityEvent]
    private(set) var seenAt: Date

    @ObservationIgnored private let store: any KeyValueStore

    private static let seenKey = "activity.seenAt"

    init(events: [ActivityEvent], store: any KeyValueStore) {
        self.store = store
        self.events = ActivityRetentionPolicy.retained(events, now: .now)
        seenAt = store.decode(Date.self, forKey: Self.seenKey) ?? .now
    }

    var unreadCount: Int {
        events.filter { $0.date > seenAt }.count
    }

    func log(_ title: String, detail: String, outcome: ActivityEvent.Outcome) {
        log(title, detail: detail, outcome: outcome, kind: nil, target: nil)
    }

    func log(_ title: String, detail: String, outcome: ActivityEvent.Outcome, kind: NotificationKind?, target: ActivityTarget?) {
        let event = ActivityEvent(id: UUID(), title: title, detail: detail, date: .now, outcome: outcome, kind: kind, target: target)
        events = ActivityRetentionPolicy.retained([event] + events, now: .now)
        save()
    }

    func markSeen() {
        seenAt = .now
        store.encode(seenAt, forKey: Self.seenKey)
    }

    func clear() {
        events.removeAll()
        save()
    }

    private func save() {
        store.encode(events, forKey: PreferenceKeys.recentEvents)
    }
}
