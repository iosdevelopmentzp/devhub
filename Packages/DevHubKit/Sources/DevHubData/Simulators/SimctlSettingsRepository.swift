import Foundation
import DevHubDomain

struct SimctlSettingsRepository: SimulatorSettingsRepository {
    let simctl: SimctlRunner

    init(shell: ShellRunner) {
        simctl = SimctlRunner(shell: shell)
    }

    func apply(_ setting: SimulatorSetting, udid: String) async throws {
        for arguments in Self.commands(for: setting, udid: udid) {
            try await simctl.run(arguments, failure: SimulatorError.command)
        }
    }

    func screenshot(udid: String, to path: String, cutsCorners: Bool) async throws {
        try await simctl.run(Self.screenshotArguments(udid: udid, path: path, cutsCorners: cutsCorners), failure: SimulatorError.command)
    }

    func record(udid: String, to path: String, onStarted: @escaping @Sendable () -> Void) async throws {
        let output = RecordingOutput()
        let status = try await simctl.shell.stream("xcrun", Self.recordArguments(udid: udid, path: path), cwd: nil, environment: [:], stop: .interrupt) { line in
            output.add(line)
            if line.contains(Self.startedLine) {
                onStarted()
            }
        }
        guard status == 0 else {
            throw SimulatorError.command(output.message ?? "simctl recordVideo exited with code \(status).")
        }
        guard FileManager.default.fileExists(atPath: path) else {
            throw SimulatorError.command("simctl did not save the recording to \(path).")
        }
    }

    static func screenshotArguments(udid: String, path: String, cutsCorners: Bool) -> [String] {
        ["io", udid, "screenshot"] + (cutsCorners ? ["--mask=alpha"] : []) + [path]
    }

    static let startedLine = "Recording started"

    static func recordArguments(udid: String, path: String) -> [String] {
        ["simctl", "io", udid, "recordVideo", "--codec=h264", "--force", path]
    }

    static func commands(for setting: SimulatorSetting, udid: String) -> [[String]] {
        switch setting {
        case .appearance(let appearance):
            [["ui", udid, "appearance", appearance.rawValue]]
        case .textSize(let size):
            [["ui", udid, "content_size", size.rawValue]]
        case .cleanStatusBar:
            [[
                "status_bar", udid, "override",
                "--time", "9:41",
                "--dataNetwork", "wifi",
                "--wifiMode", "active",
                "--wifiBars", "3",
                "--cellularMode", "active",
                "--cellularBars", "4",
                "--batteryState", "charged",
                "--batteryLevel", "100",
            ]]
        case .resetStatusBar:
            [["status_bar", udid, "clear"]]
        case let .location(latitude, longitude):
            [["location", udid, "set", "\(latitude),\(longitude)"]]
        case .clearLocation:
            [["location", udid, "clear"]]
        case let .language(code, locale):
            [
                ["spawn", udid, "defaults", "write", "-g", "AppleLanguages", "-array", code],
                ["spawn", udid, "defaults", "write", "-g", "AppleLocale", "-string", locale],
            ]
        case let .privacy(change, service, bundleID):
            [["privacy", udid, change.rawValue, service.rawValue] + (bundleID.isEmpty ? [] : [bundleID])]
        }
    }
}

private final class RecordingOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []

    var message: String? {
        let text = lock.withLock { lines.suffix(5).joined(separator: "\n") }.trimmed
        return text.isEmpty ? nil : text
    }

    func add(_ line: String) {
        lock.withLock { lines.append(line) }
    }
}
