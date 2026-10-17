import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct IdentityPanelMapperTests {
    let config = AppIdentityFixture.config
    let noSettings = SimulatorIdentitySettings(hasApplied: false)
    let uuid = "8C2F6A1E-5B3D-4E7A-9F10-2D4C6B8A0E13"

    @Test func environmentTintPerEnvironment() {
        #expect(IdentityPanelMapper.environmentTint("prod") == .red)
        #expect(IdentityPanelMapper.environmentTint("dev") == .purple)
        #expect(IdentityPanelMapper.environmentTint("qa") == .teal)
        #expect(IdentityPanelMapper.environmentTint(nil) == .teal)
    }

    @Test func modelWithoutIdentity() {
        let model = panel(identity: nil, settings: noSettings, isApplying: false, buildIsRunning: false, cleanInstallIsOn: false)

        #expect(model.lastLaunchText == nil)
        #expect(model.isInstalled == false)
        #expect(model.notInstalledText == "com.example.app is not installed here. Build & Run first; the settings below apply on that launch.")
        #expect(model.environmentTag == TagModel("qa", tint: .teal))
        #expect(model.environmentNote == "Debug default, nothing stored")
        #expect(model.apiHost == nil)
        #expect(model.deviceID == nil)
        #expect(model.deviceIDPlaceholder == "unknown, the app has not sent requests yet")
        #expect(model.userName == nil)
        #expect(model.userPublicID == nil)
        #expect(model.userPlaceholder == "unknown")
        #expect(model.version == "—")
        #expect(model.hooksTag == TagModel(
            "no APP_DEVICE_ID hook",
            tint: .red,
            systemImage: "xmark",
            hint: "A Release build or an old branch. A custom device ID needs a Debug build of a branch that reads APP_DEVICE_ID."
        ))
        #expect(model.launchTitle == "Launch")
        #expect(model.launchTint == nil)
        #expect(model.canLaunch == false)
    }

    @Test func modelWithInstalledIdentity() throws {
        let model = panel(identity: AppIdentityFixture.installed, settings: noSettings, isApplying: false, buildIsRunning: false, cleanInstallIsOn: false)

        let lastLaunch = try #require(model.lastLaunchText)
        #expect(lastLaunch.hasPrefix("last launch "))
        #expect(model.isInstalled)
        #expect(model.environmentTag == TagModel("dev", tint: .purple))
        #expect(model.environmentNote == nil)
        #expect(model.apiHost == "api.dev.example.com")
        #expect(model.deviceID == "devhub-3f9a1c2e")
        #expect(model.userName == "Sam Test")
        #expect(model.userPublicID == "u_48213")
        #expect(model.userPlaceholder == "not logged in")
        #expect(model.version == "4.12.0 (812)")
        #expect(model.hooksTag.text == "debug hooks")
        #expect(model.hooksTag.tint == .green)
        var kept = AppIdentityFixture.installed
        kept.keepsDeviceID = true
        #expect(panel(identity: kept, settings: noSettings, isApplying: false, buildIsRunning: false, cleanInstallIsOn: false).hooksTag.text == "debug hooks · ID kept")
        #expect(model.launch == IdentityPanelMapper.launch(config: config, settings: noSettings, actualDeviceID: AppIdentityFixture.installed.lastDeviceID, savedDeviceIDs: [], aliases: [:]))
    }

    @Test func canLaunchNeedsInstalledAppAndNoWork() {
        let identity = AppIdentityFixture.fresh

        #expect(panel(identity: identity, settings: noSettings, isApplying: false, buildIsRunning: false, cleanInstallIsOn: false).canLaunch)
        #expect(panel(identity: identity, settings: noSettings, isApplying: true, buildIsRunning: false, cleanInstallIsOn: false).canLaunch == false)
        #expect(panel(identity: identity, settings: noSettings, isApplying: false, buildIsRunning: true, cleanInstallIsOn: false).canLaunch == false)
        #expect(panel(identity: .notInstalled, settings: noSettings, isApplying: false, buildIsRunning: false, cleanInstallIsOn: false).canLaunch == false)
    }

    @Test func cleanInstallChangesTheLaunchButton() {
        let identity = AppIdentityFixture.fresh
        var differentDevice = noSettings
        differentDevice.desiredDeviceID = "devhub-77b0e4d1"

        let plain = panel(identity: identity, settings: noSettings, isApplying: false, buildIsRunning: false, cleanInstallIsOn: false)
        let forced = panel(identity: identity, settings: noSettings, isApplying: false, buildIsRunning: false, cleanInstallIsOn: true)
        let needed = panel(identity: identity, settings: differentDevice, isApplying: false, buildIsRunning: false, cleanInstallIsOn: false)

        #expect(plain.launchTitle == "Launch")
        #expect(plain.launchTint == nil)
        #expect(forced.launchTitle == "Reinstall & Launch")
        #expect(forced.launchTint == .orange)
        #expect(needed.launchTitle == "Reinstall & Launch")
        #expect(needed.launchTint == .orange)
    }

    @Test func summaryWithStoredEnvironmentAndUser() {
        var settings = noSettings
        settings.desiredDeviceID = "devhub-3f9a1c2e"

        let summary = IdentityPanelMapper.summary(for: AppIdentityFixture.installed, settings: settings, aliases: [:], mockState: nil, isApplying: true)

        #expect(summary.isApplying)
        #expect(summary.applyingText == "Applying device settings…")
        #expect(summary.environmentTag == TagModel("dev", tint: .purple, hint: "Environment stored in the app"))
        #expect(summary.deviceID == "devhub-3f9a1c2e")
        #expect(summary.userText == "Sam Test · u_48213")
        #expect(summary.userCopyValue == "u_48213")
        #expect(summary.userCopyLabel == "user u_48213")
        #expect(summary.userIcon == "person.fill")
        #expect(summary.notLoggedInText == nil)
        #expect(summary.nextDeviceTag == nil)
    }

    @Test func summaryWithoutStoredEnvironmentOrUser() {
        var identity = AppIdentityFixture.fresh
        identity.lastDeviceID = uuid

        let summary = IdentityPanelMapper.summary(for: identity, settings: noSettings, aliases: [:], mockState: nil, isApplying: false)

        #expect(summary.environmentTag == TagModel("qa", tint: .teal, hint: "Environment: the Debug default, nothing stored in the app"))
        #expect(summary.userText == nil)
        #expect(summary.userCopyValue == nil)
        #expect(summary.userCopyLabel == nil)
        #expect(summary.notLoggedInText == "not logged in")
        #expect(summary.nextDeviceTag == nil)
    }

    @Test func summaryWithoutDeviceIDHasNoLoggedOutText() {
        let summary = IdentityPanelMapper.summary(for: AppIdentityFixture.fresh, settings: noSettings, aliases: [:], mockState: nil, isApplying: false)

        #expect(summary.notLoggedInText == nil)
    }

    @Test func summaryShowsTheNextDeviceWhenItDiffers() {
        var settings = noSettings
        settings.desiredDeviceID = "devhub-77b0e4d1"

        let summary = IdentityPanelMapper.summary(for: AppIdentityFixture.installed, settings: settings, aliases: [:], mockState: nil, isApplying: false)

        #expect(summary.nextDeviceTag == TagModel("next: devhub-77b0e4d1", tint: .orange, hint: "The next launch from DevHub uses this device ID"))
    }

    @Test func mockTagShowsTheServerAndWhetherTheAppUsesIt() {
        let running = MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api-qa.example.com", status: .running(port: 52001))
        let mock = MockServerState(mode: .mock, setID: nil, upstreamHost: "api-qa.example.com", status: .running(port: 52001))

        #expect(IdentityPanelMapper.mockTag(state: nil, apiHost: "api-qa.example.com") == nil)
        #expect(IdentityPanelMapper.mockTag(state: running, apiHost: nil)?.text == "passthrough :52001 → api-qa.example.com")
        #expect(IdentityPanelMapper.mockTag(state: running, apiHost: "127.0.0.1:52001")?.tint == .teal)
        #expect(IdentityPanelMapper.mockTag(state: mock, apiHost: "127.0.0.1:52001")?.tint == .purple)
        #expect(IdentityPanelMapper.mockTag(state: running, apiHost: "api-qa.example.com")?.text == "passthrough :52001 · app bypasses it")
        #expect(IdentityPanelMapper.mockTag(state: running, apiHost: "127.0.0.1:50000")?.text == "passthrough :52001 · app on an old port")
        #expect(IdentityPanelMapper.mockTag(state: MockServerState(mode: .mock, setID: nil, upstreamHost: "x", status: .failed("boom")), apiHost: nil)?.tint == .red)
    }

    @Test func launchListsEnvironmentsAndSavedIDs() {
        let launch = IdentityPanelMapper.launch(config: config, settings: noSettings, actualDeviceID: nil, savedDeviceIDs: ["devhub-1", "devhub-2"], aliases: ["devhub-1": " Sam QA ", "devhub-2": "  "])

        #expect(launch.environments == ["qa", "dev", "prod"])
        #expect(launch.savedDeviceIDs == [
            SavedDeviceIDModel(id: "devhub-1", title: "Sam QA · devhub-1"),
            SavedDeviceIDModel(id: "devhub-2", title: "devhub-2")
        ])
        #expect(launch.productionTag == nil)
        #expect(launch.canEditAlias == false)
        #expect(launch.aliasPlaceholder == "enter a device ID first")
    }

    @Test func aliasNeedsADesiredDeviceID() {
        var settings = noSettings
        settings.desiredDeviceID = "devhub-1"

        let launch = IdentityPanelMapper.launch(config: config, settings: settings, actualDeviceID: nil, savedDeviceIDs: [], aliases: [:])

        #expect(launch.canEditAlias)
        #expect(launch.aliasPlaceholder == "a name for this device ID")

        let current = IdentityPanelMapper.launch(config: config, settings: noSettings, actualDeviceID: "real", savedDeviceIDs: [], aliases: [:])
        #expect(current.canEditAlias)
        #expect(current.aliasPlaceholder == "a name for the simulator's current ID")
    }

    @Test func aliasIsShownNextToTheDeviceID() {
        var settings = noSettings
        settings.desiredDeviceID = "devhub-2"
        let aliases = ["devhub-3f9a1c2e": "Sam QA", "devhub-2": "Bob QA"]
        let identity = AppIdentity(isInstalled: true, version: "1.0", hasDebugHooks: true, lastDeviceID: "devhub-3f9a1c2e")

        let summary = IdentityPanelMapper.summary(for: identity, settings: settings, aliases: aliases, mockState: nil, isApplying: false)
        let panel = IdentityPanelMapper.model(
            for: identity,
            config: config,
            settings: settings,
            savedDeviceIDs: [],
            aliases: aliases,
            isApplying: false,
            buildIsRunning: false,
            cleanInstallIsOn: false
        )

        #expect(summary.deviceAlias == "Sam QA")
        #expect(summary.deviceID == "devhub-3f9a1c2e")
        #expect(summary.nextDeviceTag?.text == "next: Bob QA · devhub-2")
        #expect(panel.deviceAlias == "Sam QA")
        #expect(panel.deviceID == "devhub-3f9a1c2e")
    }

    @Test func launchWarnsAboutProduction() {
        var settings = noSettings
        settings.desiredEnvironment = "prod"

        let launch = IdentityPanelMapper.launch(config: config, settings: settings, actualDeviceID: nil, savedDeviceIDs: [], aliases: [:])

        #expect(launch.productionTag == TagModel("production backend", tint: .red, systemImage: "exclamationmark.triangle.fill"))
    }

    @Test func cleanInstallNoteTexts() {
        let same = IdentityPanelMapper.cleanInstallNote(needsCleanInstall: false, cleanInstallIsOn: false)
        let on = IdentityPanelMapper.cleanInstallNote(needsCleanInstall: false, cleanInstallIsOn: true)
        let needed = IdentityPanelMapper.cleanInstallNote(needsCleanInstall: true, cleanInstallIsOn: true)

        #expect(same == CleanInstallNoteModel(
            icon: "info.circle",
            iconTint: .secondary,
            text: "Same device ID as now: the app is updated in place and the session stays."
        ))
        #expect(on == CleanInstallNoteModel(
            icon: "exclamationmark.triangle.fill",
            iconTint: .orange,
            text: "Clean install is on: the next launch deletes the app and resets the simulator keychain first."
        ))
        #expect(needed == CleanInstallNoteModel(
            icon: "exclamationmark.triangle.fill",
            iconTint: .orange,
            text: "The actual device ID differs: the next launch deletes the app, resets the simulator keychain and installs it again. The session is lost."
        ))
    }

    @Test func needsCleanInstallFollowsThePolicy() {
        var identity = AppIdentityFixture.fresh
        identity.lastDeviceID = uuid
        var desired = noSettings
        desired.desiredDeviceID = "devhub-1"

        #expect(IdentityPanelMapper.needsCleanInstall(identity: nil, settings: desired, savedDeviceIDs: []) == false)
        #expect(IdentityPanelMapper.needsCleanInstall(identity: identity, settings: noSettings, savedDeviceIDs: []) == false)
        #expect(IdentityPanelMapper.needsCleanInstall(identity: identity, settings: noSettings, savedDeviceIDs: [uuid]))
        #expect(IdentityPanelMapper.needsCleanInstall(identity: identity, settings: desired, savedDeviceIDs: []))
    }

    private func panel(
        identity: AppIdentity?,
        settings: SimulatorIdentitySettings,
        isApplying: Bool,
        buildIsRunning: Bool,
        cleanInstallIsOn: Bool
    ) -> IdentityPanelModel {
        IdentityPanelMapper.model(
            for: identity,
            config: config,
            settings: settings,
            savedDeviceIDs: [],
            aliases: [:],
            isApplying: isApplying,
            buildIsRunning: buildIsRunning,
            cleanInstallIsOn: cleanInstallIsOn
        )
    }
}
