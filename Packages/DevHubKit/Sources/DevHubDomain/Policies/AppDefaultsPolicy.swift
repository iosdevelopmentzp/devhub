import Foundation

package enum AppDefaultsPolicy {
    package static let editableKinds: [AppDefault.Kind] = [.string, .integer, .float, .bool]

    package static func isEditable(_ kind: AppDefault.Kind) -> Bool {
        editableKinds.contains(kind)
    }

    package static func value(kind: AppDefault.Kind, text: String) -> AppDefaultValue? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .string:
            return .string(text)
        case .integer:
            return Int(trimmed).map(AppDefaultValue.integer)
        case .float:
            return Double(trimmed).map(AppDefaultValue.float)
        case .bool:
            return bool(trimmed).map(AppDefaultValue.bool)
        case .date, .data, .array, .dictionary:
            return nil
        }
    }

    package static func toggled(_ entry: AppDefault) -> AppDefaultValue? {
        guard entry.kind == .bool, let current = bool(entry.text) else { return nil }
        return .bool(current == false)
    }

    package static func isValidKey(_ key: String, in suite: AppDefaultsSuite) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty == false && suite.entries.contains { $0.key == trimmed } == false
    }

    package static func matches(_ entry: AppDefault, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return true }
        return entry.key.localizedCaseInsensitiveContains(trimmed) || entry.text.localizedCaseInsensitiveContains(trimmed)
    }

    private static func bool(_ text: String) -> Bool? {
        switch text.lowercased() {
        case "true", "yes", "1": true
        case "false", "no", "0": false
        default: nil
        }
    }
}
