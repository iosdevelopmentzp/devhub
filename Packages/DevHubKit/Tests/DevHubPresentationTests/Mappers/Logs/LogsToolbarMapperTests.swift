import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct LogsToolbarMapperTests {
    private func stream(lines: [AppLogLine] = [], pending: [AppLogLine] = [], isPaused: Bool = false, dropped: Int = 0) -> LogStream {
        var stream = LogStream(id: "sim", name: "iPhone 17", process: "App", subsystem: "", minimumLevel: .debug)
        stream.lines = lines
        stream.pending = pending
        stream.isPaused = isPaused
        stream.dropped = dropped
        return stream
    }

    @Test func pauseTitleShowsPendingLinesOnlyWhilePaused() {
        let line = AppLogLine(id: 1, date: nil, level: .info, category: "", message: "a")

        #expect(LogsToolbarMapper.model(stream: stream(pending: [line]), visibleLineCount: 0).pauseTitle == "Pause")
        #expect(LogsToolbarMapper.model(stream: stream(isPaused: true), visibleLineCount: 0).pauseTitle == "Pause")
        #expect(LogsToolbarMapper.model(stream: stream(pending: [line, line], isPaused: true), visibleLineCount: 0).pauseTitle == "Paused · 2 new")
    }

    @Test func copyAndClearNeedLines() {
        let line = AppLogLine(id: 1, date: nil, level: .info, category: "", message: "a")
        let empty = LogsToolbarMapper.model(stream: stream(), visibleLineCount: 0)
        let three = LogsToolbarMapper.model(stream: stream(lines: [line, line, line]), visibleLineCount: 3)
        let waiting = LogsToolbarMapper.model(stream: stream(pending: [line], isPaused: true), visibleLineCount: 0)

        #expect(empty.canCopy == false)
        #expect(empty.canClear == false)
        #expect(empty.copyLabel == "0 log lines")
        #expect(three.canCopy)
        #expect(three.canClear)
        #expect(three.copyLabel == "3 log lines")
        #expect(waiting.canClear)
    }

    @Test func countsAndDroppedLines() {
        let line = AppLogLine(id: 1, date: nil, level: .info, category: "", message: "a")

        #expect(LogsToolbarMapper.model(stream: stream(lines: [line, line]), visibleLineCount: 1).lineCountText == "1 of 2 lines")
        #expect(LogsToolbarMapper.model(stream: stream(), visibleLineCount: 0).droppedText == nil)
        #expect(LogsToolbarMapper.model(stream: stream(dropped: 12), visibleLineCount: 0).droppedText == "12 dropped")
    }

    @Test func transcriptJoinsLevelCategoryAndMessage() {
        let lines = [
            AppLogLine(id: 1, date: nil, level: .error, category: "Net", message: "Lost connection"),
            AppLogLine(id: 2, date: nil, level: .notice, category: "", message: "Started")
        ]

        #expect(LogsToolbarMapper.transcript(for: lines) == "Error\tNet\tLost connection\nDefault\t\tStarted")
        #expect(LogsToolbarMapper.transcript(for: []) == "")
    }
}
