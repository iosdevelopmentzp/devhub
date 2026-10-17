import Foundation

nonisolated struct LogStream: Identifiable, Hashable, Sendable {
    static let capacity = 5000

    let simulatorID: String
    var name: String
    var process: String
    var subsystem: String
    var level: LogLevelFilter
    var lines: [LogLine] = []
    var pending: [LogLine] = []
    var dropped = 0
    var isPaused = false
    var isRunning = false
    var error: String?

    var id: String { simulatorID }

    var filter: LogFilter {
        LogFilter(process: process, subsystem: subsystem)
    }

    var saved: SavedLogStream {
        SavedLogStream(simulatorID: simulatorID, name: name, process: process, subsystem: subsystem, level: level)
    }

    init(simulatorID: String, name: String, process: String, subsystem: String, level: LogLevelFilter) {
        self.simulatorID = simulatorID
        self.name = name
        self.process = process
        self.subsystem = subsystem
        self.level = level
    }

    init(saved: SavedLogStream) {
        self.init(simulatorID: saved.simulatorID, name: saved.name, process: saved.process, subsystem: saved.subsystem, level: saved.level)
    }

    mutating func receive(_ incoming: [LogLine]) {
        guard incoming.isEmpty == false else { return }
        if isPaused {
            pending.append(contentsOf: incoming)
            dropped += Self.trim(&pending)
        } else {
            lines.append(contentsOf: incoming)
            dropped += Self.trim(&lines)
        }
    }

    mutating func resume() {
        isPaused = false
        let waiting = pending
        pending.removeAll()
        receive(waiting)
    }

    mutating func clear() {
        lines.removeAll()
        pending.removeAll()
        dropped = 0
    }

    private static func trim(_ target: inout [LogLine]) -> Int {
        guard target.count > capacity else { return 0 }
        let extra = target.count - capacity
        target.removeFirst(extra)
        return extra
    }
}
