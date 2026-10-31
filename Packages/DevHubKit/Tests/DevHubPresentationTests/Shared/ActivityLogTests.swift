import DevHubDomain
import DevHubMocks
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ActivityLogTests {
    private let store = InMemoryKeyValueStore()

    @Test func startsWithGivenEventsAndDropsOldOnes() {
        let recent = ActivityEvent(id: UUID(), title: "Recent", detail: "", date: .now, outcome: .info)
        let old = ActivityEvent(id: UUID(), title: "Old", detail: "", date: Date(timeIntervalSinceNow: -31 * 86_400), outcome: .info)

        #expect(ActivityLog(events: [recent, old], store: store).events == [recent])
    }

    @Test func logInsertsAtTheFrontWithKindAndTarget() throws {
        let log = ActivityLog(events: [], store: store)

        log.log("First", detail: "a", outcome: .success)
        log.log("Second", detail: "b", outcome: .failure, kind: .build, target: .build)

        #expect(log.events.map(\.title) == ["Second", "First"])
        let newest = try #require(log.events.first)
        #expect(newest.detail == "b")
        #expect(newest.outcome == .failure)
        #expect(newest.kind == .build)
        #expect(newest.target == .build)
        #expect(log.events.last?.kind == nil)
    }

    @Test func keepsTheNewestFiveHundred() {
        let log = ActivityLog(events: [], store: store)

        for index in 0..<502 {
            log.log("Event \(index)", detail: "", outcome: .info)
        }

        #expect(log.events.count == 500)
        #expect(log.events.first?.title == "Event 501")
        #expect(log.events.last?.title == "Event 2")
    }

    @Test func eventsAreSavedAndLoadedThroughTheStore() {
        let log = ActivityLog(events: [], store: store)
        log.log("Saved", detail: "d", outcome: .success, kind: .tests, target: .worktree(path: "/w"))

        let saved = store.decode([ActivityEvent].self, forKey: PreferenceKeys.recentEvents)

        #expect(saved == log.events)
        #expect(saved?.first?.target == .worktree(path: "/w"))
    }

    @Test func unreadCountsEventsAfterTheLastLookAndMarkSeenResetsIt() {
        let log = ActivityLog(events: [], store: store)
        #expect(log.unreadCount == 0)

        log.log("A", detail: "", outcome: .info)
        log.log("B", detail: "", outcome: .info)
        #expect(log.unreadCount == 2)

        log.markSeen()

        #expect(log.unreadCount == 0)
        #expect(ActivityLog(events: log.events, store: store).unreadCount == 0)
    }

    @Test func clearRemovesEverythingAndTheSavedCopy() {
        let log = ActivityLog(events: [], store: store)
        log.log("Event", detail: "", outcome: .info)

        log.clear()

        #expect(log.events.isEmpty)
        #expect(store.decode([ActivityEvent].self, forKey: PreferenceKeys.recentEvents) == [])
    }
}
