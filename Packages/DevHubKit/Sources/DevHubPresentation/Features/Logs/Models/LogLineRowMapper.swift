import Foundation
import DevHubDomain
import DevHubUI

enum LogLineRowMapper {

    static func model(for line: AppLogLine) -> LogLineRowModel {
        LogLineRowModel(
            id: line.id,
            timestamp: LogTimestamp.text(line.date),
            levelTitle: title(for: line.level),
            levelTint: tint(for: line.level),
            levelOpacity: line.level == .debug ? 0.5 : 1,
            category: line.category.isEmpty ? nil : line.category,
            message: line.message,
            messageTint: line.level >= .error ? tint(for: line.level) : nil
        )
    }

    static func title(for level: AppLogLine.Level) -> String {
        switch level {
        case .debug: "Debug"
        case .info: "Info"
        case .notice: "Default"
        case .error: "Error"
        case .fault: "Fault"
        }
    }

    private static func tint(for level: AppLogLine.Level) -> Tint {
        switch level {
        case .debug: .secondary
        case .info: .blue
        case .notice: .gray
        case .error: .red
        case .fault: .purple
        }
    }
}
