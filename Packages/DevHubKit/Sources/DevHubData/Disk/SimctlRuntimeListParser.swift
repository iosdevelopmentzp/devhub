import Foundation
import DevHubDomain

enum SimctlRuntimeListParser {
    private struct Runtime: Decodable {
        let identifier: String
        let version: String?
        let build: String?
        let platformIdentifier: String?
        let sizeBytes: Int64?
        let deletable: Bool?
        let lastUsedAt: String?
    }

    static func items(from data: Data) throws -> [DiskCleanupItem] {
        let runtimes: [String: Runtime]
        do {
            runtimes = try JSONDecoder().decode([String: Runtime].self, from: data)
        } catch {
            throw DiskCleanupError.command("simctl runtime list returned an answer DevHub cannot read.")
        }
        return runtimes.values
            .filter { $0.deletable ?? false }
            .map { runtime in
                DiskCleanupItem(
                    id: "runtime:" + runtime.identifier,
                    kind: .simulatorRuntime,
                    name: [platformName(runtime.platformIdentifier), runtime.version].compactMap { $0 }.joined(separator: " "),
                    detail: runtime.build,
                    size: runtime.sizeBytes,
                    lastUsed: runtime.lastUsedAt.flatMap(ISO8601.date(from:)),
                    runtimeID: runtime.identifier
                )
            }
            .sorted { lhs, rhs in
                (lhs.name ?? "").localizedStandardCompare(rhs.name ?? "") == .orderedDescending
            }
    }

    static func platformName(_ identifier: String?) -> String? {
        switch identifier {
        case "com.apple.platform.iphonesimulator": "iOS"
        case "com.apple.platform.appletvsimulator": "tvOS"
        case "com.apple.platform.watchsimulator": "watchOS"
        case "com.apple.platform.xrsimulator": "visionOS"
        default: identifier?.split(separator: ".").last.map(String.init)
        }
    }
}
