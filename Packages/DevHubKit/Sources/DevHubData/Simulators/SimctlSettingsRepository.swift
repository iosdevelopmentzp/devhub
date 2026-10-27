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

    func screenshot(udid: String, to path: String) async throws {
        try await simctl.run(["io", udid, "screenshot", path], failure: SimulatorError.command)
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
