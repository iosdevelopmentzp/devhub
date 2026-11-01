import Foundation
import DevHubDomain

enum XcodeInstallationParser {
    static func appPaths(fromSpotlight output: String) -> [String] {
        let lines = output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        let apps = lines.filter { $0.hasSuffix(".app") && $0.contains("/.Trash/") == false }
        var seen: Set<String> = []
        return apps.filter { seen.insert($0).inserted }
    }

    static func installation(appPath: String, versionPlist: [String: Any]?) -> XcodeInstallation? {
        guard let version = versionPlist?["CFBundleShortVersionString"] as? String, version.isEmpty == false else { return nil }
        return XcodeInstallation(appPath: appPath, version: version, build: versionPlist?["ProductBuildVersion"] as? String)
    }

    static func sorted(_ installations: [XcodeInstallation]) -> [XcodeInstallation] {
        installations.sorted { left, right in
            let order = left.version.compare(right.version, options: .numeric)
            guard order == .orderedSame else { return order == .orderedDescending }
            return left.appPath < right.appPath
        }
    }
}
