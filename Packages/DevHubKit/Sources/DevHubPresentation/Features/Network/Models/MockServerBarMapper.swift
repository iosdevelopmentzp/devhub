import Foundation
import DevHubDomain
import DevHubUI

enum MockServerBarMapper {
    static let modeOptions = MockMode.allCases.map { MockServerBarModel.ModeOption(id: $0, title: title(for: $0)) }

    static func model(
        settings: MockSimulatorSettings,
        state: MockServerState?,
        sets: [MockSet],
        hasSimulator: Bool,
        isApplying: Bool,
        needsApply: Bool,
        error: String?,
        app: InstalledApp?,
        report: AppStateReport?,
        lastLaunch: LaunchRecord?,
        profiles: [LaunchProfile]
    ) -> MockServerBarModel {
        let status = status(state: state, isApplying: isApplying)
        let app = appStatus(state: state, app: app, report: report, lastLaunch: lastLaunch, profiles: profiles)
        return MockServerBarModel(
            modes: modeOptions,
            mode: settings.mode,
            showsSetPicker: settings.mode == .mock,
            sets: sets.map { MockServerBarModel.SetOption(id: $0.id, title: "\($0.name) · \(CountText.count($0.rules.count, "rule"))") },
            selectedSetID: sets.contains { $0.id == settings.setID } ? settings.setID : nil,
            applyTitle: isApplying ? "Relaunching…" : "Apply & Relaunch",
            canApply: hasSimulator && isApplying == false && (settings.mode != .mock || sets.contains { $0.id == settings.setID }),
            isApplyProminent: needsApply && isApplying == false,
            statusText: status.text,
            statusTint: status.tint,
            statusHint: status.hint,
            appText: app?.text,
            appTint: app?.tint ?? .secondary,
            appHint: app?.hint ?? "",
            error: error
        )
    }

    static func title(for mode: MockMode) -> String {
        switch mode {
        case .off: "Off"
        case .passthrough: "Passthrough"
        case .mock: "Mock"
        }
    }

    static func appStatus(state: MockServerState?, app: InstalledApp?, report: AppStateReport?, lastLaunch: LaunchRecord?, profiles: [LaunchProfile]) -> (text: String, tint: Tint, hint: String)? {
        guard let state, let port = state.port else { return nil }
        let serverURL = MockLaunchEnvironment.baseURL(port: port)
        guard app?.isInstalled != false else {
            return ("App not installed on this simulator", .secondary, "Build & Run installs it; the launch from DevHub points it to the server")
        }
        guard let lastLaunch else {
            return ("Launched outside DevHub: traffic may bypass the server", .orange, "DevHub has no launch of this app on record. Press Apply & Relaunch so the app gets \(serverURL).")
        }
        guard lastLaunch.baseURL == serverURL else {
            let text = lastLaunch.baseURL.map { "App points to an old DevHub server (\($0)): relaunch" } ?? "The last launch did not use the server: relaunch"
            return (text, .orange, "The server listens on \(serverURL). Launch the app from DevHub again.")
        }
        if let host = report?.host, host.hasPrefix("127.0.0.1") == false {
            return (
                "App reports \(host): launched without DevHub",
                .orange,
                "The server runs, but the status script says the app talks to \(host). It was probably started from Xcode or the home screen. Launch the app from DevHub."
            )
        }
        let appProfile = profiles.first { $0.id == lastLaunch.profileID }
        let serverProfile = MockUpstreamPolicy.profile(ofHost: state.upstreamHost, in: profiles)
        if let appProfile, let serverProfile, appProfile.id != serverProfile.id {
            return (
                "App is on \(appProfile.title), the server forwards to \(serverProfile.title): relaunch",
                .orange,
                "The app was launched with \(appProfile.title) but its requests reach \(state.upstreamHost). A launch from DevHub moves the server to the app's profile."
            )
        }
        return ("App goes through DevHub (\(serverURL))", .green, "As of the last launch from DevHub the app talks to the DevHub server, which forwards to \(state.upstreamHost)")
    }

    private static func status(state: MockServerState?, isApplying: Bool) -> (text: String, tint: Tint, hint: String) {
        if isApplying {
            return ("Relaunching the app…", .orange, "DevHub restarts the app with the new network settings")
        }
        guard let state else {
            return ("Server off", .secondary, "The app talks to its real hosts. Pick a mode and press Apply & Relaunch.")
        }
        switch state.status {
        case .running(let port):
            let mode = state.mode == .mock ? "mocks" : "passthrough"
            return (
                "Port \(port) → \(state.upstreamHost)",
                .green,
                "The app talks to \(MockLaunchEnvironment.baseURL(port: port)) (\(mode)). DevHub forwards the rest to \(state.upstreamHost)."
            )
        case .failed(let message):
            return ("Server failed", .red, message)
        }
    }
}
