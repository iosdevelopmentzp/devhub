import Foundation
import DevHubDomain
import DevHubUI

enum IdentityPanelMapper {

    static func model(
        for identity: AppIdentity?,
        config: DeviceIdentityConfig,
        settings: SimulatorIdentitySettings,
        savedDeviceIDs: [String],
        aliases: [String: String],
        isApplying: Bool,
        buildIsRunning: Bool,
        cleanInstallIsOn: Bool
    ) -> IdentityPanelModel {
        let needsCleanInstall = needsCleanInstall(identity: identity, settings: settings, savedDeviceIDs: savedDeviceIDs)
        let willCleanInstall = cleanInstallIsOn || needsCleanInstall
        let isInstalled = identity?.isInstalled == true
        return IdentityPanelModel(
            lastLaunchText: identity?.lastLaunch.map { "last launch \($0.relativeDescription)" },
            isInstalled: isInstalled,
            notInstalledText: "\(config.bundleID) is not installed here. Build & Run first; the settings below apply on that launch.",
            environmentTag: TagModel(
                identity?.storedEnvironment ?? config.defaultEnvironment,
                tint: environmentTint(identity?.storedEnvironment)
            ),
            environmentNote: identity?.storedEnvironment == nil ? "Debug default, nothing stored" : nil,
            apiHost: identity?.apiHost,
            deviceAlias: alias(of: identity?.lastDeviceID, in: aliases),
            deviceID: identity?.lastDeviceID,
            deviceIDPlaceholder: "unknown, the app has not sent requests yet",
            userName: identity?.user?.name,
            userPublicID: identity?.user?.publicID,
            userPlaceholder: identity?.lastDeviceID == nil ? "unknown" : "not logged in",
            version: identity?.version ?? "—",
            hooksTag: hooksTag(hasDebugHooks: identity?.hasDebugHooks == true, keepsDeviceID: identity?.keepsDeviceID == true, config: config),
            launch: launch(config: config, settings: settings, actualDeviceID: identity?.lastDeviceID, savedDeviceIDs: savedDeviceIDs, aliases: aliases),
            cleanInstallNote: cleanInstallNote(needsCleanInstall: needsCleanInstall, cleanInstallIsOn: cleanInstallIsOn),
            launchTitle: willCleanInstall ? "Reinstall & Launch" : "Launch",
            launchTint: willCleanInstall ? .orange : nil,
            canLaunch: isApplying == false && buildIsRunning == false && isInstalled
        )
    }

    static func summary(for identity: AppIdentity, settings: SimulatorIdentitySettings, aliases: [String: String], mockState: MockServerState?, isApplying: Bool) -> IdentitySummaryModel {
        IdentitySummaryModel(
            isApplying: isApplying,
            applyingText: "Applying device settings…",
            environmentTag: TagModel(
                identity.storedEnvironment ?? "qa",
                tint: environmentTint(identity.storedEnvironment),
                hint: identity.storedEnvironment == nil ? "Environment: the Debug default, nothing stored in the app" : "Environment stored in the app"
            ),
            deviceAlias: alias(of: identity.lastDeviceID, in: aliases),
            deviceID: identity.lastDeviceID,
            userText: identity.user.map { "\($0.name) · \($0.publicID)" },
            userCopyValue: identity.user?.publicID,
            userCopyLabel: identity.user.map { "user \($0.publicID)" },
            userIcon: "person.fill",
            notLoggedInText: identity.user == nil && identity.lastDeviceID != nil ? "not logged in" : nil,
            nextDeviceTag: nextDeviceTag(desired: settings.desiredDeviceID, actual: identity.lastDeviceID, aliases: aliases),
            mockTag: mockTag(state: mockState, apiHost: identity.apiHost)
        )
    }

    static func launch(
        config: DeviceIdentityConfig,
        settings: SimulatorIdentitySettings,
        actualDeviceID: String?,
        savedDeviceIDs: [String],
        aliases: [String: String]
    ) -> LaunchIdentityModel {
        LaunchIdentityModel(
            environments: config.environments,
            savedDeviceIDs: savedDeviceIDs.map { SavedDeviceIDModel(id: $0, title: title(of: $0, in: aliases)) },
            canEditAlias: settings.desiredDeviceID != nil || actualDeviceID != nil,
            aliasPlaceholder: aliasPlaceholder(desiredDeviceID: settings.desiredDeviceID, actualDeviceID: actualDeviceID),
            productionTag: productionTag(environment: settings.desiredEnvironment)
        )
    }

    static func cleanInstallNote(needsCleanInstall: Bool, cleanInstallIsOn: Bool) -> CleanInstallNoteModel {
        let isClean = needsCleanInstall || cleanInstallIsOn
        return CleanInstallNoteModel(
            icon: isClean ? "exclamationmark.triangle.fill" : "info.circle",
            iconTint: isClean ? .orange : .secondary,
            text: cleanInstallText(needsCleanInstall: needsCleanInstall, cleanInstallIsOn: cleanInstallIsOn)
        )
    }

    static func needsCleanInstall(identity: AppIdentity?, settings: SimulatorIdentitySettings, savedDeviceIDs: [String]) -> Bool {
        CleanInstallPolicy.needsCleanInstall(
            identity: identity,
            settings: settings,
            desiredDeviceID: settings.desiredDeviceID,
            savedDeviceIDs: savedDeviceIDs
        )
    }

    private static func aliasPlaceholder(desiredDeviceID: String?, actualDeviceID: String?) -> String {
        if desiredDeviceID != nil { return "a name for this device ID" }
        if actualDeviceID != nil { return "a name for the simulator's current ID" }
        return "enter a device ID first"
    }

    static func alias(of deviceID: String?, in aliases: [String: String]) -> String? {
        guard let deviceID, let alias = aliases[deviceID]?.trimmed, alias.isEmpty == false else { return nil }
        return alias
    }

    static func title(of deviceID: String, in aliases: [String: String]) -> String {
        alias(of: deviceID, in: aliases).map { "\($0) · \(deviceID)" } ?? deviceID
    }

    static func environmentTint(_ environment: String?) -> Tint {
        switch environment {
        case "prod": .red
        case "dev": .purple
        default: .teal
        }
    }

    static func mockTag(state: MockServerState?, apiHost: String?) -> TagModel? {
        guard let state else { return nil }
        let mode = state.mode == .mock ? "mock" : "passthrough"
        switch state.status {
        case .failed(let message):
            return TagModel("mock server failed", tint: .red, systemImage: "xmark.octagon.fill", hint: message)
        case .running(let port):
            if let apiHost, apiHost.hasPrefix("127.0.0.1") == false {
                return TagModel(
                    "\(mode) :\(port) · app bypasses it",
                    tint: .orange,
                    systemImage: "exclamationmark.triangle.fill",
                    hint: "A DevHub server runs on 127.0.0.1:\(port), but the app's last requests went to \(apiHost): it was launched without DevHub (Xcode or the home screen). Launch it from DevHub."
                )
            }
            if let apiHost, apiHost != "127.0.0.1:\(port)" {
                return TagModel(
                    "\(mode) :\(port) · app on an old port",
                    tint: .orange,
                    systemImage: "exclamationmark.triangle.fill",
                    hint: "The app's last requests went to \(apiHost), the server now listens on 127.0.0.1:\(port). Launch the app from DevHub again."
                )
            }
            return TagModel(
                "\(mode) :\(port) → \(state.upstreamHost)",
                tint: state.mode == .mock ? .purple : .teal,
                systemImage: "network",
                hint: "The app launched from DevHub talks to 127.0.0.1:\(port); DevHub forwards to \(state.upstreamHost)"
            )
        }
    }

    private static func productionTag(environment: String?) -> TagModel? {
        guard environment == "prod" else { return nil }
        return TagModel("production backend", tint: .red, systemImage: "exclamationmark.triangle.fill")
    }

    private static func nextDeviceTag(desired: String?, actual: String?, aliases: [String: String]) -> TagModel? {
        guard let desired, desired != actual else { return nil }
        return TagModel("next: \(title(of: desired, in: aliases))", tint: .orange, hint: "The next launch from DevHub uses this device ID")
    }

    private static func hooksTag(hasDebugHooks: Bool, keepsDeviceID: Bool, config: DeviceIdentityConfig) -> TagModel {
        if hasDebugHooks, keepsDeviceID {
            return TagModel(
                "debug hooks · ID kept",
                tint: .green,
                systemImage: "checkmark",
                hint: "The build keeps the device ID set from DevHub: Xcode and the home screen launch with it until a launch from DevHub with an empty Device ID."
            )
        }
        if hasDebugHooks {
            return TagModel(
                "debug hooks",
                tint: .green,
                systemImage: "checkmark",
                hint: "The build reads \(config.deviceIDVariable) for this launch only: Xcode and the home screen launch with the app's own ID. A build with the DevHub change in KeychainService keeps the ID."
            )
        }
        return TagModel(
            "no \(config.deviceIDVariable) hook",
            tint: .red,
            systemImage: "xmark",
            hint: "A Release build or an old branch. A custom device ID needs a Debug build of a branch that reads \(config.deviceIDVariable)."
        )
    }

    private static func cleanInstallText(needsCleanInstall: Bool, cleanInstallIsOn: Bool) -> String {
        if needsCleanInstall {
            return "The actual device ID differs: the next launch deletes the app, resets the simulator keychain and installs it again. The session is lost."
        }
        if cleanInstallIsOn {
            return "Clean install is on: the next launch deletes the app and resets the simulator keychain first."
        }
        return "Same device ID as now: the app is updated in place and the session stays."
    }
}
