import Foundation
import DevHubDomain
import DevHubUI

enum LogsToolbarMapper {

    static func model(stream: LogStream, visibleLineCount: Int) -> LogsToolbarModel {
        LogsToolbarModel(
            pauseTitle: stream.isPaused && stream.pending.isEmpty == false ? "Paused · \(stream.pending.count) new" : "Pause",
            canCopy: visibleLineCount > 0,
            copyLabel: CountText.invariant(visibleLineCount, "log lines"),
            canClear: stream.lines.isEmpty == false || stream.pending.isEmpty == false,
            lineCountText: "\(visibleLineCount) of \(CountText.count(stream.lines.count, "line"))",
            droppedText: stream.dropped > 0 ? "\(stream.dropped) dropped" : nil
        )
    }

    static func transcript(for lines: [AppLogLine]) -> String {
        lines
            .map { "\(LogLineRowMapper.title(for: $0.level))\t\($0.category)\t\($0.message)" }
            .joined(separator: "\n")
    }
}
