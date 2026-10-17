import Foundation

nonisolated enum InfoPlistParser {
    static func executableName(in data: Data) -> String? {
        guard let object = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return nil }
        guard let name = object["CFBundleExecutable"] as? String, name.isEmpty == false else { return nil }
        return name
    }
}
