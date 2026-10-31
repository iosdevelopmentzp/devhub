import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
package final class CommandLog {
    struct Entry: Identifiable, Hashable {
        let id: UUID
        var command: String
        var cwd: String?
        var kind: CommandKind
        var operationID: UUID?
        var startedAt: Date
        var finishedAt: Date?
        var exitCode: Int32?
        var error: String?
        var lines: [String]
        var droppedLines: Int

        var isRunning: Bool { finishedAt == nil }
        var isFailure: Bool { error != nil || (exitCode.map { $0 != 0 } ?? false) }
        var output: String { lines.joined(separator: "\n") }
    }

    private static let maxEntries = 300
    private static let maxLinesPerEntry = 4_000
    static let hiddenOutput = "Output hidden: it contains credentials."
    static let appLogOutput = "App log lines are shown in the Logs tab only."

    private(set) var entries: [Entry] = []

    package init() {}

    func handle(_ event: CommandEvent) {
        switch event.payload {
        case .started(let command, let cwd, let kind, let operationID):
            entries.append(Entry(id: event.id, command: command, cwd: cwd, kind: kind, operationID: operationID, startedAt: .now, lines: hiddenLines(for: kind), droppedLines: 0))
            if entries.count > Self.maxEntries {
                entries.removeFirst(entries.count - Self.maxEntries)
            }
        case .output(let lines):
            guard let index = entries.firstIndex(where: { $0.id == event.id }), entries[index].kind.hidesOutput == false else { return }
            entries[index].lines.append(contentsOf: lines)
            let overflow = entries[index].lines.count - Self.maxLinesPerEntry
            if overflow > 0 {
                entries[index].lines.removeFirst(overflow)
                entries[index].droppedLines += overflow
            }
        case .finished(let exitCode, let error):
            guard let index = entries.firstIndex(where: { $0.id == event.id }) else { return }
            entries[index].finishedAt = .now
            entries[index].exitCode = exitCode
            entries[index].error = error
        }
    }

    func clear() {
        entries.removeAll { $0.isRunning == false }
    }

    private func hiddenLines(for kind: CommandKind) -> [String] {
        switch kind {
        case .secret: [Self.hiddenOutput]
        case .appLog: [Self.appLogOutput]
        case .action, .read: []
        }
    }
}
