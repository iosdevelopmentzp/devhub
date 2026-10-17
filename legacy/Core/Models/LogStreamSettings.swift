import Foundation

nonisolated enum LogLevelFilter: String, Codable, CaseIterable, Hashable, Sendable {
    case all
    case info
    case standard
    case errors

    var title: String {
        switch self {
        case .all: "All"
        case .info: "Info+"
        case .standard: "Default+"
        case .errors: "Errors"
        }
    }

    func includes(_ level: LogLine.Level) -> Bool {
        switch self {
        case .all: true
        case .info: level >= .info
        case .standard: level >= .notice
        case .errors: level >= .error
        }
    }
}

nonisolated struct SavedLogStream: Codable, Hashable, Sendable {
    var simulatorID: String
    var name: String
    var process: String
    var subsystem: String
    var level: LogLevelFilter
}

nonisolated struct LogFilter: Hashable, Sendable {
    var process: String
    var subsystem: String

    var predicate: String? {
        let subsystem = subsystem.trimmingCharacters(in: .whitespaces)
        if subsystem.isEmpty == false {
            return "subsystem == \"\(Self.escaped(subsystem))\""
        }
        let process = process.trimmingCharacters(in: .whitespaces)
        guard process.isEmpty == false else { return nil }
        return "process == \"\(Self.escaped(process))\""
    }

    private static func escaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
