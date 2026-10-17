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
        identity: AppIdentity?,
        config: DeviceIdentityConfig?
    ) -> MockServerBarModel {
        let status = status(state: state, isApplying: isApplying)
        let app = appStatus(state: state, identity: identity, config: config)
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

    static func appStatus(state: MockServerState?, identity: AppIdentity?, config: DeviceIdentityConfig?) -> (text: String, tint: Tint, hint: String)? {
        guard let state, let port = state.port else { return nil }
        guard let identity, identity.isInstalled else {
            return ("App not installed on this simulator", .secondary, "Build & Run installs it; the launch from DevHub points it to the server")
        }
        guard let apiHost = identity.apiHost else {
            return ("App has not sent requests yet", .secondary, "DevHub reads the host from the app's session log after the first request")
        }
        guard apiHost.hasPrefix("127.0.0.1") else {
            return (
                "App talks to \(apiHost) directly: launched without DevHub",
                .orange,
                "The server runs, but the app was started from Xcode or the home screen and ignores it. Launch the app from DevHub (Apply & Relaunch, Launch or Build & Run)."
            )
        }
        guard apiHost == "127.0.0.1:\(port)" else {
            return ("App points to an old DevHub port (\(apiHost)): relaunch", .orange, "The server now listens on 127.0.0.1:\(port). Launch the app from DevHub again.")
        }
        let appEnvironment = identity.storedEnvironment ?? config?.defaultEnvironment
        let serverEnvironment = config.flatMap { UpstreamResolver.environmentName(ofHost: state.upstreamHost, config: $0) }
        if let appEnvironment, let serverEnvironment, appEnvironment != serverEnvironment {
            return (
                "App is on \(appEnvironment), the server forwards to \(serverEnvironment): relaunch",
                .orange,
                "The app stores \(appEnvironment) but its requests reach \(state.upstreamHost). A launch from DevHub moves the server to the app's environment."
            )
        }
        return ("App goes through DevHub (127.0.0.1:\(port))", .green, "The app's last requests went to the DevHub server, which forwards them to \(state.upstreamHost)")
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
