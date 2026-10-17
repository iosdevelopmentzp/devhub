import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ActivityLogTests {
    @Test func startsWithGivenEvents() {
        let event = ActivityEvent(id: UUID(), title: "Old", detail: "", date: .now, outcome: .info)

        #expect(ActivityLog(events: [event]).events == [event])
    }

    @Test func logInsertsAtTheFront() throws {
        let log = ActivityLog(events: [])

        log.log("First", detail: "a", outcome: .success)
        log.log("Second", detail: "b", outcome: .failure)

        #expect(log.events.map(\.title) == ["Second", "First"])
        let newest = try #require(log.events.first)
        #expect(newest.detail == "b")
        #expect(newest.outcome == .failure)
    }

    @Test func keepsTheNewestEight() {
        let log = ActivityLog(events: [])

        for index in 0..<10 {
            log.log("Event \(index)", detail: "", outcome: .info)
        }

        #expect(log.events.count == 8)
        #expect(log.events.first?.title == "Event 9")
        #expect(log.events.last?.title == "Event 2")
    }

    @Test func clearRemovesEverything() {
        let log = ActivityLog(events: [])
        log.log("Event", detail: "", outcome: .info)

        log.clear()

        #expect(log.events.isEmpty)
    }
}
