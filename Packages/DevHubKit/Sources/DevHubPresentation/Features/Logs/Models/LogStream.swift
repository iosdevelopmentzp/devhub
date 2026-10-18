import Foundation
import DevHubDomain
import DevHubUI

struct LogStream: Identifiable, Equatable {
    static let capacity = 5_000

    let id: Simulator.ID
    var name: String
    var process: String
    var subsystem: String
    var minimumLevel: AppLogLine.Level
    var lines: [AppLogLine] = []
    var pending: [AppLogLine] = []
    var dropped = 0
    var isPaused = false
    var isRunning = false
    var error: String?

    init(id: Simulator.ID, name: String, process: String, subsystem: String, minimumLevel: AppLogLine.Level) {
        self.id = id
        self.name = name
        self.process = process
        self.subsystem = subsystem
        self.minimumLevel = minimumLevel
    }

    init(settings: LogStreamSettings) {
        self.init(
            id: settings.udid,
            name: settings.name,
            process: settings.process,
            subsystem: settings.subsystem,
            minimumLevel: AppLogLine.Level(rawValue: settings.level) ?? .debug
        )
    }

    var settings: LogStreamSettings {
        LogStreamSettings(udid: id, name: name, process: process, subsystem: subsystem, level: minimumLevel.rawValue)
    }

    var filter: AppLogFilter {
        AppLogFilter(process: process, subsystem: subsystem)
    }

    var visibleLines: [AppLogLine] {
        lines.filter { $0.level >= minimumLevel }
    }

    mutating func receive(_ incoming: [AppLogLine]) {
        guard incoming.isEmpty == false else { return }
        if isPaused {
            pending.append(contentsOf: incoming)
            dropped += Self.trim(&pending)
        } else {
            lines.append(contentsOf: incoming)
            dropped += Self.trim(&lines)
        }
    }

    mutating func setPaused(_ paused: Bool) {
        isPaused = paused
        guard paused == false else { return }
        let waiting = pending
        pending = []
        receive(waiting)
    }

    mutating func clear() {
        lines = []
        pending = []
        dropped = 0
    }

    private static func trim(_ target: inout [AppLogLine]) -> Int {
        let overflow = target.count - capacity
        guard overflow > 0 else { return 0 }
        target.removeFirst(overflow)
        return overflow
    }
}
