import Testing
@testable import DevHubDomain

@Suite struct CleanInstallPolicyTests {
    private let config = LaunchIdentityConfig(variable: "APP_DEVICE_ID")
    private let installed = InstalledApp(isInstalled: true, version: "1.0", hasIdentityHook: true, keepsIdentity: false, storedProfileID: nil)

    @Test func noIdentityConfigNeedsNoCleanInstall() {
        #expect(needs(desired: "X", config: nil) == false)
    }

    @Test func turnedOffCleanInstallNeedsNoCleanInstall() {
        var config = config
        config.cleanInstallOnChange = false

        #expect(needs(desired: "X", config: config) == false)
    }

    @Test func appNotInstalledNeedsNoCleanInstall() {
        #expect(needs(app: .notInstalled, desired: "X") == false)
    }

    @Test func reportedIDEqualToTheDesiredIDNeedsNoCleanInstall() {
        #expect(needs(report: report("A"), desired: "A") == false)
    }

    @Test func reportedIDDifferentFromTheDesiredIDNeedsACleanInstall() {
        #expect(needs(report: report("A"), desired: "B"))
    }

    @Test func reportWinsOverTheAppliedID() {
        #expect(needs(report: report("A"), settings: applied("B"), desired: "B"))
    }

    @Test func appliedIDIsUsedWithoutAReport() {
        #expect(needs(settings: applied("A"), desired: "A") == false)
        #expect(needs(settings: applied("B"), desired: "A"))
    }

    @Test func noDesiredIDLeavesTheOwnIDAlone() {
        #expect(needs(report: report("own"), desired: nil) == false)
        #expect(needs(report: report("own"), settings: applied("A"), desired: nil) == false)
    }

    @Test func noDesiredIDRemovesAnIDThatDevHubSet() {
        #expect(needs(settings: applied("A"), desired: nil))
        #expect(needs(report: report("A"), settings: applied("A"), desired: nil))
        #expect(needs(report: report("A"), desired: nil, saved: ["A"]))
    }

    @Test func appliedIDIsIgnoredWhenNotApplied() {
        let settings = SimulatorLaunchSettings(desiredIdentity: nil, appliedIdentity: "A", hasApplied: false, lastLaunch: nil)

        #expect(needs(settings: settings, desired: "A"))
    }

    @Test func noDesiredAndNoKnownIDNeedsNoCleanInstall() {
        #expect(needs(desired: nil) == false)
    }

    private func report(_ identity: String?) -> AppStateReport {
        AppStateReport(identity: identity, profile: nil, host: nil, user: nil, version: nil)
    }

    private func applied(_ identity: String?) -> SimulatorLaunchSettings {
        SimulatorLaunchSettings(desiredIdentity: nil, appliedIdentity: identity, hasApplied: true, lastLaunch: nil)
    }

    private func needs(
        app: InstalledApp? = nil,
        report: AppStateReport? = nil,
        settings: SimulatorLaunchSettings = .empty,
        desired: String?,
        saved: [String] = [],
        config: LaunchIdentityConfig? = LaunchIdentityConfig(variable: "APP_DEVICE_ID")
    ) -> Bool {
        CleanInstallPolicy.needsCleanInstall(app: app ?? installed, report: report, settings: settings, desiredIdentity: desired, savedIdentities: saved, config: config)
    }
}
