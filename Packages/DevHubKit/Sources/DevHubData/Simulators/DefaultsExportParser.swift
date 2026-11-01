import Foundation
import DevHubDomain

enum DefaultsExportParser {
    static let textLimit = 300

    static func entries(from text: String) -> [AppDefault]? {
        guard let data = text.data(using: .utf8),
              let plist = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] else { return nil }
        return plist
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { entry(key: $0.key, value: $0.value) }
    }

    static func entry(key: String, value: Any) -> AppDefault {
        AppDefault(key: key, kind: kind(of: value), text: limited(text(of: value, quoted: false)))
    }

    private static func kind(of value: Any) -> AppDefault.Kind {
        switch value {
        case is String: .string
        case let number as NSNumber: numberKind(number)
        case is Date: .date
        case is Data: .data
        case is [Any]: .array
        case is [String: Any]: .dictionary
        default: .string
        }
    }

    private static func numberKind(_ number: NSNumber) -> AppDefault.Kind {
        if CFGetTypeID(number) == CFBooleanGetTypeID() { return .bool }
        return CFNumberIsFloatType(number) ? .float : .integer
    }

    private static func text(of value: Any, quoted: Bool) -> String {
        switch value {
        case let string as String:
            return quoted ? "\"\(string)\"" : string
        case let number as NSNumber:
            return numberText(number)
        case let date as Date:
            return date.formatted(.iso8601)
        case let data as Data:
            return "\(data.count) bytes"
        case let array as [Any]:
            return "[" + array.map { text(of: $0, quoted: true) }.joined(separator: ", ") + "]"
        case let dictionary as [String: Any]:
            let pairs = dictionary.sorted { $0.key < $1.key }.map { "\($0.key): \(text(of: $0.value, quoted: true))" }
            return "{" + pairs.joined(separator: ", ") + "}"
        default:
            return "\(value)"
        }
    }

    private static func numberText(_ number: NSNumber) -> String {
        switch numberKind(number) {
        case .bool: number.boolValue ? "true" : "false"
        case .float: "\(number.doubleValue)"
        default: "\(number.int64Value)"
        }
    }

    private static func limited(_ text: String) -> String {
        guard text.count > textLimit else { return text }
        return String(text.prefix(textLimit)) + "…"
    }
}
