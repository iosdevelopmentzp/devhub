import Foundation

nonisolated enum InstalledAppsParser {
    static func userApps(from text: String) -> [InstalledApp]? {
        guard let data = text.data(using: .utf8),
              let root = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return nil }
        return root.compactMap { key, value -> InstalledApp? in
            guard let info = value as? [String: Any], info["ApplicationType"] as? String == "User" else { return nil }
            let name = info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? key
            return InstalledApp(bundleID: key, name: name)
        }
        .sorted { $0.bundleID < $1.bundleID }
    }
}
