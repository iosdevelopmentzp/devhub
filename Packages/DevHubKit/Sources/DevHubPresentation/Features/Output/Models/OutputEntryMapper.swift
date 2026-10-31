import Foundation
import DevHubDomain
import DevHubUI

enum OutputEntryMapper {

    private static let previewLines = 8

    static func visibleEntries(_ entries: [CommandLog.Entry], showsReads: Bool, failedOnly: Bool, query: String) -> [CommandLog.Entry] {
        let query = query.trimmingCharacters(in: .whitespaces)
        return entries.filter { entry in
            guard showsReads || entry.kind != .read else { return false }
            guard failedOnly == false || entry.isFailure else { return false }
            guard query.isEmpty == false else { return true }
            return entry.command.localizedCaseInsensitiveContains(query)
                || entry.output.localizedCaseInsensitiveContains(query)
                || (entry.error?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    static func model(for entry: CommandLog.Entry, isExpanded: Bool, now: Date) -> OutputEntryModel {
        OutputEntryModel(
            id: entry.id,
            command: entry.command,
            commandLine: "$ " + entry.command,
            folder: entry.cwd?.abbreviatingHome,
            folderPath: entry.cwd,
            startedText: ClockTime.text(entry.startedAt),
            durationText: DurationFormat.text((entry.finishedAt ?? now).timeIntervalSince(entry.startedAt)),
            isRunning: entry.isRunning,
            statusIcon: entry.isFailure ? "xmark.circle.fill" : "checkmark.circle.fill",
            statusTint: statusTint(for: entry),
            statusHint: entry.isFailure ? entry.exitCode.map { "Exit code \($0)" } ?? "Failed" : nil,
            isExpanded: isExpanded,
            canExpand: entry.lines.count > previewLines,
            expandIcon: isExpanded ? "chevron.up" : "chevron.down",
            expandHint: isExpanded ? "Show less" : "Show all \(entry.lines.count) lines",
            output: entry.lines.isEmpty ? nil : visibleOutput(for: entry, isExpanded: isExpanded),
            fullOutput: entry.lines.isEmpty ? nil : entry.output,
            outputTint: entry.isFailure ? .red : nil,
            error: entry.error
        )
    }

    static func transcript(for entry: CommandLog.Entry) -> String {
        var parts = ["$ " + entry.command]
        if let cwd = entry.cwd { parts.insert("# in \(cwd)", at: 0) }
        if entry.lines.isEmpty == false { parts.append(entry.output) }
        if let exitCode = entry.exitCode, exitCode != 0 { parts.append("# exit code \(exitCode)") }
        if let error = entry.error { parts.append("# \(error)") }
        return parts.joined(separator: "\n")
    }

    static func transcript(for entries: [CommandLog.Entry]) -> String {
        entries.map { transcript(for: $0) }.joined(separator: "\n\n")
    }

    private static func statusTint(for entry: CommandLog.Entry) -> Tint {
        if entry.isFailure { return .red }
        return entry.kind == .read ? .secondary : .green
    }

    private static func visibleOutput(for entry: CommandLog.Entry, isExpanded: Bool) -> String {
        let lines = isExpanded ? entry.lines : Array(entry.lines.suffix(previewLines))
        var text = lines.joined(separator: "\n")
        if isExpanded == false, entry.lines.count > previewLines {
            text = "… \(entry.lines.count - previewLines) more lines above\n" + text
        } else if entry.droppedLines > 0 {
            text = "… \(entry.droppedLines) earlier lines dropped\n" + text
        }
        return text
    }
}
