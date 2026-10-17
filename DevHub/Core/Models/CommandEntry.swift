import Foundation

nonisolated enum CommandKind: String, Hashable, Sendable {
    case read
    case action
    case secret
    case appLog
}

nonisolated struct CommandEntry: Identifiable, Hashable, Sendable {
    static let maxLines = 4000
    static let cancelledMessage = "Cancelled"

    let id: UUID
    let command: String
    let cwd: String?
    let kind: CommandKind
    let startedAt: Date
    var finishedAt: Date?
    var exitCode: Int32?
    var error: String?
    var lines: [String] = []
    var droppedLineCount = 0

    var isRunning: Bool { finishedAt == nil }

    var isCancelled: Bool { error == Self.cancelledMessage }

    var isFailure: Bool {
        if isCancelled {
            return false
        }
        if error != nil {
            return true
        }
        guard let exitCode else { return false }
        return exitCode != 0
    }

    var recordsOutput: Bool {
        kind == .action || kind == .read
    }

    var hiddenOutputNotice: String? {
        switch kind {
        case .secret: "Output hidden: it contains credentials."
        case .appLog: "App log lines are shown in the Logs tab only."
        case .read, .action: nil
        }
    }

    var durationText: String? {
        guard let finishedAt else { return nil }
        let seconds = finishedAt.timeIntervalSince(startedAt)
        if seconds < 1 {
            return "\(Int((seconds * 1000).rounded())) ms"
        }
        return String(format: "%.1f s", seconds)
    }

    var exitText: String? {
        if let error {
            return error
        }
        return exitCode.map { "exit \($0)" }
    }

    var plainText: String {
        var parts = ["$ \(command)"]
        if let cwd {
            parts.append("in \(cwd)")
        }
        parts.append(contentsOf: lines)
        if let notice = hiddenOutputNotice {
            parts.append(notice)
        }
        let summary = [exitText, durationText].compactMap { $0 }.joined(separator: ", ")
        if summary.isEmpty == false {
            parts.append("(\(summary))")
        }
        return parts.joined(separator: "\n")
    }

    mutating func append(_ newLines: [String]) {
        lines.append(contentsOf: newLines)
        guard lines.count > Self.maxLines else { return }
        let excess = lines.count - Self.maxLines
        lines.removeFirst(excess)
        droppedLineCount += excess
    }
}

nonisolated enum CommandEvent: Sendable {
    case started(id: UUID, command: String, cwd: String?, kind: CommandKind, date: Date)
    case output(id: UUID, lines: [String])
    case finished(id: UUID, exitCode: Int32?, error: String?, date: Date)
}
