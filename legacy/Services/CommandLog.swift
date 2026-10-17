import Foundation
import Observation

@MainActor
@Observable
final class CommandLog {
    static let maxEntries = 300

    private(set) var entries: [CommandEntry] = []

    @ObservationIgnored var onFailure: (CommandEntry) -> Void = { _ in }

    init(recorder: CommandRecorder) {
        recorder.attach { [weak self] event in
            guard let self else { return }
            apply(event)
        }
    }

    var runningCount: Int {
        entries.filter(\.isRunning).count
    }

    func clear() {
        entries.removeAll { $0.isRunning == false }
    }

    private func apply(_ event: CommandEvent) {
        switch event {
        case let .started(id, command, cwd, kind, date):
            entries.insert(CommandEntry(id: id, command: command, cwd: cwd, kind: kind, startedAt: date), at: 0)
            if entries.count > Self.maxEntries {
                entries.removeLast(entries.count - Self.maxEntries)
            }
        case let .output(id, lines):
            guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
            entries[index].append(lines)
        case let .finished(id, exitCode, error, date):
            guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
            entries[index].finishedAt = date
            entries[index].exitCode = exitCode
            entries[index].error = error
            let entry = entries[index]
            if entry.isFailure, entry.kind != .read, entry.kind != .secret {
                onFailure(entry)
            }
        }
    }
}
