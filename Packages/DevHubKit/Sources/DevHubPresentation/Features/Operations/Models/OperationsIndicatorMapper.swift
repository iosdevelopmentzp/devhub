import Foundation
import DevHubDomain
import DevHubUI

enum OperationsIndicatorMapper {
    static let hint = "Show the operations of this session"

    static func model(for records: [OperationRecord]) -> OperationsIndicatorModel? {
        guard records.isEmpty == false else { return nil }
        let running = records.filter(\.isRunning)
        let unseenFailures = records.filter { $0.failureMessage != nil && $0.isSeen == false }.count
        if running.count == 1, let record = running.first {
            let text = record.progressText.map { "\(record.title): \($0)" } ?? record.title
            return OperationsIndicatorModel(text: text, icon: "circle.dotted", tint: .blue, textTint: .secondary, isRunning: true, hint: hint)
        }
        if running.count > 1 {
            return OperationsIndicatorModel(text: "\(running.count) running", icon: "circle.dotted", tint: .blue, textTint: .secondary, isRunning: true, hint: hint)
        }
        if unseenFailures > 0 {
            return OperationsIndicatorModel(text: "\(unseenFailures) failed", icon: "xmark.octagon.fill", tint: .red, textTint: .red, isRunning: false, hint: hint)
        }
        return OperationsIndicatorModel(text: nil, icon: "list.bullet.rectangle", tint: .secondary, textTint: .secondary, isRunning: false, hint: hint)
    }
}
