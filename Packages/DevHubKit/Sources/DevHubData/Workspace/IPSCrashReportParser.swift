import Foundation
import DevHubDomain

enum IPSCrashReportParser {
    static let frameLimit = 40

    static func parse(_ text: String, path: String, fallbackDate: Date) -> CrashReport? {
        let parts = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
        guard let headerLine = parts.first, let header = object(String(headerLine)) else { return nil }
        let body = parts.count > 1 ? object(String(parts[1])) ?? [:] : [:]
        let bundleInfo = body["bundleInfo"] as? [String: Any]
        let processName = header["name"] as? String ?? header["app_name"] as? String ?? body["procName"] as? String
        guard let processName, processName.isEmpty == false else { return nil }
        let procPath = body["procPath"] as? String ?? ""
        let exception = body["exception"] as? [String: Any]
        return CrashReport(
            path: path,
            processName: processName,
            bundleID: header["bundleID"] as? String ?? bundleInfo?["CFBundleIdentifier"] as? String,
            appVersion: header["app_version"] as? String ?? bundleInfo?["CFBundleShortVersionString"] as? String,
            date: (header["timestamp"] as? String).flatMap(date) ?? fallbackDate,
            simulatorID: simulatorID(in: procPath),
            exceptionType: exception?["type"] as? String,
            signal: exception?["signal"] as? String,
            subtype: exception?["subtype"] as? String,
            messages: messages(in: body),
            frames: frames(in: body, appBundle: appBundle(of: procPath))
        )
    }

    static func header(_ text: String) -> [String: Any]? {
        guard let line = text.split(separator: "\n", maxSplits: 1).first else { return nil }
        return object(String(line))
    }

    static func simulatorID(in procPath: String) -> String? {
        guard let range = procPath.range(of: "/CoreSimulator/Devices/") else { return nil }
        let id = procPath[range.upperBound...].prefix { $0 != "/" }
        return id.count == 36 ? String(id) : nil
    }

    static func date(_ timestamp: String) -> Date? {
        let plain = timestamp.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: plain)
    }

    private static func object(_ text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static func appBundle(of procPath: String) -> String? {
        guard let range = procPath.range(of: ".app/", options: .backwards) else { return nil }
        return String(procPath[..<range.lowerBound]) + ".app"
    }

    private static func messages(in body: [String: Any]) -> [String] {
        guard let asi = body["asi"] as? [String: Any] else { return [] }
        return asi.keys.sorted().flatMap { key in
            (asi[key] as? [String] ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        .filter { $0.isEmpty == false }
    }

    private static func frames(in body: [String: Any], appBundle: String?) -> [CrashReport.Frame] {
        let threads = body["threads"] as? [[String: Any]] ?? []
        let faulting = body["faultingThread"] as? Int
        let thread = faulting.flatMap { threads.indices.contains($0) ? threads[$0] : nil }
            ?? threads.first { $0["triggered"] as? Bool == true }
        let images = body["usedImages"] as? [[String: Any]] ?? []
        let frames = thread?["frames"] as? [[String: Any]] ?? []
        return frames.prefix(frameLimit).map { frame in
            let index = frame["imageIndex"] as? Int
            let image = index.flatMap { images.indices.contains($0) ? images[$0] : nil }
            let imagePath = image?["path"] as? String ?? ""
            return CrashReport.Frame(
                image: image?["name"] as? String ?? URL(fileURLWithPath: imagePath).lastPathComponent,
                symbol: frame["symbol"] as? String,
                file: frame["sourceFile"] as? String,
                line: frame["sourceLine"] as? Int,
                isApp: appBundle.map { imagePath.hasPrefix($0) } ?? false
            )
        }
    }
}
