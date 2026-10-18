import Foundation

package enum CleanInstallPolicy {

    package static func needsCleanInstall(
        app: InstalledApp?,
        report: AppStateReport?,
        settings: SimulatorLaunchSettings,
        desiredIdentity: String?,
        savedIdentities: [String],
        config: LaunchIdentityConfig?
    ) -> Bool {
        guard let config, config.cleansOnChange, let app, app.isInstalled else { return false }
        let actual = report?.identity ?? settings.actualIdentity
        guard let desiredIdentity else {
            guard let actual else { return false }
            return actual == settings.actualIdentity || savedIdentities.contains(actual)
        }
        return actual != desiredIdentity
    }
}
