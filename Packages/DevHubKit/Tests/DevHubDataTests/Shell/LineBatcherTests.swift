import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct LineBatcherTests {
    @Test func flushRecordsOneOutputWithPendingLines() throws {
        let recorder = SpyCommandRecorder()
        let id = UUID()
        let batcher = LineBatcher(id: id, recorder: recorder)

        batcher.add("one")
        batcher.add("two")
        batcher.flush()

        let events = recorder.events
        #expect(events.count == 1)
        let event = try #require(events.first)
        #expect(event.id == id)
        #expect(event.outputLines == ["one", "two"])
    }

    @Test func flushWithNothingPendingRecordsNothing() {
        let recorder = SpyCommandRecorder()
        let batcher = LineBatcher(id: UUID(), recorder: recorder)

        batcher.flush()

        #expect(recorder.events.isEmpty)
    }

    @Test func secondFlushRecordsOnlyNewLines() {
        let recorder = SpyCommandRecorder()
        let batcher = LineBatcher(id: UUID(), recorder: recorder)

        batcher.add("one")
        batcher.flush()
        batcher.flush()
        batcher.add("two")
        batcher.flush()

        #expect(recorder.events.map(\.outputLines) == [["one"], ["two"]])
    }
}
