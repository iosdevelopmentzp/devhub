import DevHubDomain
import Foundation
@testable import DevHubPresentation

enum IdentityContextFixture {
    static let config = LaunchIdentityConfig(variable: "APP_DEVICE_ID")

    static let profiles = [
        LaunchProfile(id: "staging", title: "Staging", upstream: "https://api.staging.example.com"),
        LaunchProfile(id: "production", title: "Production", upstream: "https://api.example.com", production: true),
    ]

    static let installedApp = InstalledApp(isInstalled: true, version: "4.12.0 (812)", hasIdentityHook: true, keepsIdentity: false, storedProfileID: nil)

    static let freshApp = InstalledApp(isInstalled: true, version: "4.12.0 (812)", hasIdentityHook: false, keepsIdentity: false, storedProfileID: nil)

    static let report = AppStateReport(identity: "devhub-3f9a1c2e", profile: "staging", host: "api.staging.example.com", user: "qa-12", version: "4.12.1 (815)")

    static func context(
        app: InstalledApp? = installedApp,
        report: AppStateReport? = nil,
        settings: SimulatorLaunchSettings = .empty,
        savedDeviceIDs: [String] = [],
        aliases: [String: String] = [:],
        isApplying: Bool = false,
        config: LaunchIdentityConfig = config
    ) -> IdentityContext {
        IdentityContext(
            config: config,
            profiles: profiles,
            app: app,
            report: report,
            settings: settings,
            savedDeviceIDs: savedDeviceIDs,
            aliases: aliases,
            isApplying: isApplying
        )
    }

    static func settings(desired: String? = nil, applied: String? = nil, lastLaunch: LaunchRecord? = nil) -> SimulatorLaunchSettings {
        SimulatorLaunchSettings(desiredIdentity: desired, appliedIdentity: applied, hasApplied: applied != nil || lastLaunch != nil, lastLaunch: lastLaunch)
    }
}
