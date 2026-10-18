import Foundation
import DevHubDomain
import DevHubUI

struct IdentityContext: Equatable {
    var config: LaunchIdentityConfig
    var profiles: [LaunchProfile]
    var app: InstalledApp?
    var report: AppStateReport?
    var settings: SimulatorLaunchSettings
    var savedDeviceIDs: [String]
    var aliases: [String: String]
    var isApplying: Bool

    var isInstalled: Bool {
        app?.isInstalled == true
    }

    var actualIdentity: String? {
        report?.identity ?? settings.actualIdentity
    }

    var needsCleanInstall: Bool {
        CleanInstallPolicy.needsCleanInstall(app: app, report: report, settings: settings, desiredIdentity: settings.desiredIdentity, savedIdentities: savedDeviceIDs, config: config)
    }

    static let preview = IdentityContext(
        config: LaunchIdentityConfig(variable: "APP_DEVICE_ID", keptVariable: "APP_KEEP_DEVICE_ID"),
        profiles: [
            LaunchProfile(id: "staging", title: "Staging", upstream: "https://api.staging.example.com"),
            LaunchProfile(id: "production", title: "Production", production: true)
        ],
        app: InstalledApp(isInstalled: true, version: "2.4.0", hasIdentityHook: true, keepsIdentity: false, storedProfileID: "staging"),
        report: AppStateReport(identity: "devhub-3f9a1c2e", profile: "staging", host: "api.staging.example.com", user: "qa-12", version: "2.4.0"),
        settings: SimulatorLaunchSettings(desiredIdentity: "devhub-77b0e4d1", appliedIdentity: "devhub-3f9a1c2e", hasApplied: true, lastLaunch: nil),
        savedDeviceIDs: ["devhub-3f9a1c2e", "devhub-77b0e4d1"],
        aliases: ["devhub-3f9a1c2e": "Sam QA"],
        isApplying: false
    )
}
