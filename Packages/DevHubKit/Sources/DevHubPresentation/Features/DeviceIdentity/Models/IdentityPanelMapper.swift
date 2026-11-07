import Foundation
import DevHubDomain
import DevHubUI

enum IdentityPanelMapper {

    static func model(context: IdentityContext, bundleID: String, buildIsRunning: Bool, cleanInstallIsOn: Bool) -> IdentityPanelModel {
        let willCleanInstall = cleanInstallIsOn || context.needsCleanInstall
        let report = context.report
        let profile = profileTag(context: context)
        return IdentityPanelModel(
            lastLaunchText: context.settings.lastLaunch.map { "last launch from DevHub \($0.date.relativeDescription)" },
            isInstalled: context.isInstalled,
            notInstalledText: "\(bundleID) is not installed here. Build & Run first; the settings below apply on that launch.",
            profileTag: profile ?? TagModel("no profile", tint: .secondary),
            profileNote: profile == nil ? "the app reports no profile" : nil,
            host: report?.host,
            deviceAlias: alias(of: context.actualIdentity, in: context.aliases),
            deviceID: context.actualIdentity,
            deviceIDPlaceholder: context.settings.hasApplied ? "own ID: the last launch from DevHub set no ID" : "unknown: no launch from DevHub yet",
            user: report?.user,
            userPlaceholder: "not reported by the status script",
            version: report?.version ?? context.app?.version ?? "—",
            hooksTag: hooksTag(app: context.app, config: context.config),
            launch: launch(context: context),
            cleanInstallNote: cleanInstallNote(context: context, cleanInstallIsOn: cleanInstallIsOn),
            launchTitle: willCleanInstall ? "Reinstall & Launch" : "Launch",
            launchTint: willCleanInstall ? .orange : nil,
            canLaunch: context.isApplying == false && buildIsRunning == false && context.isInstalled,
            canAttach: context.isPhysicalDevice == false
        )
    }

    static func summary(context: IdentityContext, mockState: MockServerState?) -> IdentitySummaryModel {
        IdentitySummaryModel(
            isApplying: context.isApplying,
            applyingText: "Launching…",
            profileTag: profileTag(context: context),
            deviceAlias: alias(of: context.actualIdentity, in: context.aliases),
            deviceID: context.actualIdentity,
            userText: context.report?.user,
            userIcon: "person.fill",
            nextDeviceTag: nextDeviceTag(desired: context.settings.desiredIdentity, actual: context.actualIdentity, aliases: context.aliases),
            mockTag: mockTag(state: mockState, host: context.report?.host, lastLaunch: context.settings.lastLaunch),
            tags: (context.report?.tags ?? []).map(ConfigTagMapper.model)
        )
    }

    static func launch(context: IdentityContext) -> LaunchIdentityModel {
        let desired = context.settings.desiredIdentity
        let actual = context.actualIdentity
        return LaunchIdentityModel(
            idPrefix: context.config.idPrefix ?? LaunchIdentityConfig.defaultPrefix,
            savedDeviceIDs: context.savedDeviceIDs.map { SavedDeviceIDModel(id: $0, title: title(of: $0, in: context.aliases)) },
            canEditAlias: desired != nil || actual != nil,
            aliasPlaceholder: aliasPlaceholder(desired: desired, actual: actual)
        )
    }

    static func cleanInstallNote(context: IdentityContext, cleanInstallIsOn: Bool) -> CleanInstallNoteModel {
        let isClean = context.needsCleanInstall || cleanInstallIsOn
        return CleanInstallNoteModel(
            icon: isClean ? "exclamationmark.triangle.fill" : "info.circle",
            iconTint: isClean ? .orange : .secondary,
            text: cleanInstallText(context: context, cleanInstallIsOn: cleanInstallIsOn)
        )
    }

    static func alias(of deviceID: String?, in aliases: [String: String]) -> String? {
        guard let deviceID, let alias = aliases[deviceID]?.trimmed, alias.isEmpty == false else { return nil }
        return alias
    }

    static func title(of deviceID: String, in aliases: [String: String]) -> String {
        alias(of: deviceID, in: aliases).map { "\($0) · \(deviceID)" } ?? deviceID
    }

    static func profileTag(context: IdentityContext) -> TagModel? {
        guard let value = context.report?.profile ?? context.app?.storedProfileID ?? context.settings.lastLaunch?.profileID else { return nil }
        let profile = context.profiles.profile(matching: value)
        let isProduction = profile?.isProduction == true
        return TagModel(
            profile?.title ?? value,
            tint: profile?.tint.map(ConfigTintMapper.tint) ?? (isProduction ? .red : .teal),
            hint: isProduction ? "A production profile: real data and real users" : "The profile the app uses now"
        )
    }

    static func mockTag(state: MockServerState?, host: String?, lastLaunch: LaunchRecord?) -> TagModel? {
        guard let state else { return nil }
        let mode = state.mode == .mock ? "mock" : "passthrough"
        switch state.status {
        case .failed(let message):
            return TagModel("mock server failed", tint: .red, systemImage: "xmark.octagon.fill", hint: message)
        case .running(let port):
            let serverURL = MockLaunchEnvironment.baseURL(port: port)
            if let host, host.hasPrefix("127.0.0.1") == false {
                return TagModel(
                    "\(mode) :\(port) · app bypasses it",
                    tint: .orange,
                    systemImage: "exclamationmark.triangle.fill",
                    hint: "The app reports \(host) as its server: it was launched without DevHub (Xcode or the home screen). Launch it from DevHub."
                )
            }
            guard lastLaunch?.baseURL == serverURL else {
                return TagModel(
                    "\(mode) :\(port) · relaunch",
                    tint: .orange,
                    systemImage: "exclamationmark.triangle.fill",
                    hint: "The last launch from DevHub did not point the app to \(serverURL). Launch the app from DevHub again."
                )
            }
            return TagModel(
                "\(mode) :\(port) → \(state.upstreamHost)",
                tint: state.mode == .mock ? .purple : .teal,
                systemImage: "network",
                hint: "As of the last launch from DevHub the app talks to \(serverURL); DevHub forwards to \(state.upstreamHost)"
            )
        }
    }

    private static func aliasPlaceholder(desired: String?, actual: String?) -> String {
        if desired != nil { return "a name for this ID" }
        if actual != nil { return "a name for the simulator's current ID" }
        return "enter an ID first"
    }

    private static func nextDeviceTag(desired: String?, actual: String?, aliases: [String: String]) -> TagModel? {
        guard let desired, desired != actual else { return nil }
        return TagModel("next: \(title(of: desired, in: aliases))", tint: .orange, hint: "The next launch from DevHub uses this ID")
    }

    private static func hooksTag(app: InstalledApp?, config: LaunchIdentityConfig) -> TagModel {
        let variable = config.variable
        if app?.hasIdentityHook == true, app?.keepsIdentity == true {
            return TagModel(
                "\(variable) · ID kept",
                tint: .green,
                systemImage: "checkmark",
                hint: "The build reads \(variable) and keeps the ID: launches from Xcode and the home screen use it too, until a launch from DevHub with an empty ID."
            )
        }
        if app?.hasIdentityHook == true {
            return TagModel(
                variable,
                tint: .green,
                systemImage: "checkmark",
                hint: "The build reads \(variable) on launches from DevHub. Xcode and the home screen launch with the app's own ID."
            )
        }
        return TagModel(
            "no \(variable) hook",
            tint: .red,
            systemImage: "xmark",
            hint: "The build does not contain \(config.marker). A custom ID needs a build that reads \(variable)."
        )
    }

    private static func cleanInstallText(context: IdentityContext, cleanInstallIsOn: Bool) -> String {
        if context.isPhysicalDevice, context.needsCleanInstall {
            return "The app on this device has another ID: the next launch deletes the app and installs the last build again. The keychain of the device stays. The session is lost."
        }
        if context.needsCleanInstall {
            return "The app on this simulator has another ID: the next launch deletes the app, resets the simulator keychain and installs it again. The session is lost."
        }
        if context.isPhysicalDevice, cleanInstallIsOn {
            return "Clean install is on: the next launch deletes the app and installs the last build again. The keychain of the device stays."
        }
        if cleanInstallIsOn {
            return "Clean install is on: the next launch deletes the app and resets the simulator keychain first."
        }
        if context.config.cleansOnChange == false {
            return "launch.identity.cleanInstallOnChange is off: the app is updated in place even when the ID changes."
        }
        return "Same ID as now: the app is updated in place and the session stays."
    }
}
