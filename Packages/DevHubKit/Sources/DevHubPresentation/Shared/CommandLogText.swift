import Foundation
import DevHubDomain
import DevHubUI

enum CommandLogText {
    static func lines(_ entry: CommandLog.Entry, head: Int, tail: Int) -> [String] {
        let exit = entry.exitCode.map { "exit \($0)" } ?? (entry.isRunning ? "running" : "no exit code")
        let duration = entry.finishedAt.map { " \(DurationFormat.text($0.timeIntervalSince(entry.startedAt)))" } ?? ""
        var lines = ["### \(ISOTimestamp.text(entry.startedAt)) \(exit)\(duration) cwd=\(entry.cwd ?? "-")", "$ \(entry.command)"]
        if let error = entry.error {
            lines.append("error: \(error)")
        }
        if entry.droppedLines > 0 {
            lines.append("(\(entry.droppedLines) earlier lines dropped by the command log)")
        }
        let output = entry.lines
        if output.count > head + tail {
            lines += output.prefix(head)
            lines.append("(\(output.count - head - tail) lines left out)")
            lines += output.suffix(tail)
        } else {
            lines += output
        }
        return lines
    }
}
