import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct IdentityPanelMapperTests {
    private typealias Fixture = IdentityContextFixture

    @Test func modelWithoutAnInstalledApp() {
        let model = panel(Fixture.context(app: nil))

        #expect(model.lastLaunchText == nil)
        #expect(model.isInstalled == false)
        #expect(model.notInstalledText == "com.example.app is not installed here. Build & Run first; the settings below apply on that launch.")
        #expect(model.profileTag == TagModel("no profile", tint: .secondary))
        #expect(model.profileNote == "the app reports no profile")
        #expect(model.host == nil)
        #expect(model.deviceID == nil)
        #expect(model.deviceIDPlaceholder == "unknown: no launch from DevHub yet")
        #expect(model.user == nil)
        #expect(model.userPlaceholder == "not reported by the status script")
        #expect(model.version == "—")
        #expect(model.hooksTag == TagModel(
            "no APP_DEVICE_ID hook",
            tint: .red,
            systemImage: "xmark",
            hint: "The build does not contain APP_DEVICE_ID. A custom ID needs a build that reads APP_DEVICE_ID."
        ))
        #expect(model.launchTitle == "Launch")
        #expect(model.launchTint == nil)
        #expect(model.canLaunch == false)
    }

    @Test func modelWithAReport() throws {
        let launch = LaunchRecord(bundleID: nil, profileID: "staging", identity: "devhub-3f9a1c2e", baseURL: nil, date: Date(timeIntervalSinceNow: -300))
        let context = Fixture.context(report: Fixture.report, settings: Fixture.settings(applied: "devhub-3f9a1c2e", lastLaunch: launch))

        let model = panel(context)

        let lastLaunch = try #require(model.lastLaunchText)
        #expect(lastLaunch.hasPrefix("last launch from DevHub "))
        #expect(model.isInstalled)
        #expect(model.profileTag == TagModel("Staging", tint: .teal, hint: "The profile the app uses now"))
        #expect(model.profileNote == nil)
        #expect(model.host == "api.staging.example.com")
        #expect(model.deviceID == "devhub-3f9a1c2e")
        #expect(model.user == "qa-12")
        #expect(model.version == "4.12.1 (815)")
        #expect(model.hooksTag.text == "APP_DEVICE_ID")
        #expect(model.hooksTag.tint == .green)
        #expect(model.launch == IdentityPanelMapper.launch(context: context))
    }

    @Test func keptIdentityIsShownOnTheHookTag() {
        var app = Fixture.installedApp
        app.keepsIdentity = true

        #expect(panel(Fixture.context(app: app)).hooksTag.text == "APP_DEVICE_ID · ID kept")
    }

    @Test func versionFallsBackToTheInstalledApp() {
        #expect(panel(Fixture.context()).version == "4.12.0 (812)")
    }

    @Test func noIDAfterALaunchFromDevHubIsTheOwnID() {
        let launch = LaunchRecord(bundleID: nil, profileID: nil, identity: nil, baseURL: nil, date: .now)

        #expect(panel(Fixture.context(settings: Fixture.settings(lastLaunch: launch))).deviceIDPlaceholder == "own ID: the last launch from DevHub set no ID")
    }

    @Test func profileComesFromTheReportThenTheStoredValueThenTheLastLaunch() {
        var stored = Fixture.installedApp
        stored.storedProfileID = "production"
        let launch = LaunchRecord(bundleID: nil, profileID: "custom", identity: nil, baseURL: nil, date: .now)

        #expect(IdentityPanelMapper.profileTag(context: Fixture.context(app: stored, report: Fixture.report))?.text == "Staging")
        #expect(IdentityPanelMapper.profileTag(context: Fixture.context(app: stored)) == TagModel("Production", tint: .red, hint: "A production profile: real data and real users"))
        #expect(IdentityPanelMapper.profileTag(context: Fixture.context(settings: Fixture.settings(lastLaunch: launch)))?.text == "custom")
        #expect(IdentityPanelMapper.profileTag(context: Fixture.context()) == nil)
    }

    @Test func profileIsFoundByTitleToo() {
        let report = AppStateReport(identity: nil, profile: "STAGING", host: nil, user: nil, version: nil)

        #expect(IdentityPanelMapper.profileTag(context: Fixture.context(report: report))?.text == "Staging")
    }

    @Test func canLaunchNeedsAnInstalledAppAndNoWork() {
        #expect(panel(Fixture.context()).canLaunch)
        #expect(panel(Fixture.context(isApplying: true)).canLaunch == false)
        #expect(panel(Fixture.context(), buildIsRunning: true).canLaunch == false)
        #expect(panel(Fixture.context(app: .notInstalled)).canLaunch == false)
    }

    @Test func cleanInstallChangesTheLaunchButton() {
        let plain = panel(Fixture.context())
        let forced = panel(Fixture.context(), cleanInstallIsOn: true)
        let needed = panel(Fixture.context(settings: Fixture.settings(desired: "devhub-77b0e4d1")))

        #expect(plain.launchTitle == "Launch")
        #expect(plain.launchTint == nil)
        #expect(forced.launchTitle == "Reinstall & Launch")
        #expect(forced.launchTint == .orange)
        #expect(needed.launchTitle == "Reinstall & Launch")
        #expect(needed.launchTint == .orange)
    }

    @Test func summaryWithAReport() {
        let context = Fixture.context(report: Fixture.report, settings: Fixture.settings(desired: "devhub-3f9a1c2e"), isApplying: true)

        let summary = IdentityPanelMapper.summary(context: context, mockState: nil)

        #expect(summary.isApplying)
        #expect(summary.applyingText == "Launching…")
        #expect(summary.profileTag?.text == "Staging")
        #expect(summary.deviceID == "devhub-3f9a1c2e")
        #expect(summary.userText == "qa-12")
        #expect(summary.userIcon == "person.fill")
        #expect(summary.nextDeviceTag == nil)
        #expect(summary.mockTag == nil)
    }

    @Test func summaryWithoutAReport() {
        let summary = IdentityPanelMapper.summary(context: Fixture.context(), mockState: nil)

        #expect(summary.profileTag == nil)
        #expect(summary.deviceID == nil)
        #expect(summary.userText == nil)
        #expect(summary.nextDeviceTag == nil)
        #expect(summary.tags.isEmpty)
    }

    @Test func summaryShowsTheNextIDWhenItDiffers() {
        let context = Fixture.context(report: Fixture.report, settings: Fixture.settings(desired: "devhub-77b0e4d1"))

        let summary = IdentityPanelMapper.summary(context: context, mockState: nil)

        #expect(summary.nextDeviceTag == TagModel("next: devhub-77b0e4d1", tint: .orange, hint: "The next launch from DevHub uses this ID"))
    }

    @Test func profileTintComesFromTheConfigAndWinsOverProduction() {
        let profiles = [
            LaunchProfile(id: "dev", title: "Dev", tint: .purple),
            LaunchProfile(id: "production", title: "Production", production: true),
            LaunchProfile(id: "beta", title: "Beta", production: true, tint: .orange)
        ]
        func tag(_ profile: String) -> TagModel? {
            let report = AppStateReport(identity: nil, profile: profile, host: nil, user: nil, version: nil)
            return IdentityPanelMapper.profileTag(context: Fixture.context(profiles: profiles, report: report))
        }

        #expect(tag("dev")?.tint == .purple)
        #expect(tag("production")?.tint == .red)
        #expect(tag("beta")?.tint == .orange)
        #expect(tag("unknown")?.tint == .teal)
    }

    @Test func summaryShowsTheTagsOfTheStateReport() {
        var report = Fixture.report
        report.tags = [ScriptViewTag(text: "beta", tint: .purple, icon: "flask", hint: "Beta build"), ScriptViewTag(text: "plain")]

        let summary = IdentityPanelMapper.summary(context: Fixture.context(report: report), mockState: nil)

        #expect(summary.tags == [
            TagModel("beta", tint: .purple, systemImage: "flask", hint: "Beta build"),
            TagModel("plain", tint: .gray)
        ])
    }

    @Test func mockTagShowsTheServerAndWhetherTheAppUsesIt() {
        let running = MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api.staging.example.com", status: .running(port: 52001))
        let mock = MockServerState(mode: .mock, setID: nil, upstreamHost: "api.staging.example.com", status: .running(port: 52001))
        let pointed = LaunchRecord(bundleID: nil, profileID: "staging", identity: nil, baseURL: "http://127.0.0.1:52001", date: .now)
        let old = LaunchRecord(bundleID: nil, profileID: "staging", identity: nil, baseURL: "http://127.0.0.1:50000", date: .now)

        #expect(IdentityPanelMapper.mockTag(state: nil, host: nil, lastLaunch: pointed) == nil)
        #expect(IdentityPanelMapper.mockTag(state: running, host: nil, lastLaunch: pointed)?.text == "passthrough :52001 → api.staging.example.com")
        #expect(IdentityPanelMapper.mockTag(state: running, host: "127.0.0.1:52001", lastLaunch: pointed)?.tint == .teal)
        #expect(IdentityPanelMapper.mockTag(state: mock, host: nil, lastLaunch: pointed)?.tint == .purple)
        #expect(IdentityPanelMapper.mockTag(state: running, host: "api.staging.example.com", lastLaunch: pointed)?.text == "passthrough :52001 · app bypasses it")
        #expect(IdentityPanelMapper.mockTag(state: running, host: nil, lastLaunch: old)?.text == "passthrough :52001 · relaunch")
        #expect(IdentityPanelMapper.mockTag(state: running, host: nil, lastLaunch: nil)?.text == "passthrough :52001 · relaunch")
        #expect(IdentityPanelMapper.mockTag(state: MockServerState(mode: .mock, setID: nil, upstreamHost: "x", status: .failed("boom")), host: nil, lastLaunch: nil)?.tint == .red)
    }

    @Test func launchListsSavedIDsWithAliases() {
        let launch = IdentityPanelMapper.launch(context: Fixture.context(savedDeviceIDs: ["devhub-1", "devhub-2"], aliases: ["devhub-1": " Sam QA ", "devhub-2": "  "]))

        #expect(launch.idPrefix == "devhub-")
        #expect(launch.savedDeviceIDs == [
            SavedDeviceIDModel(id: "devhub-1", title: "Sam QA · devhub-1"),
            SavedDeviceIDModel(id: "devhub-2", title: "devhub-2"),
        ])
        #expect(launch.canEditAlias == false)
        #expect(launch.aliasPlaceholder == "enter an ID first")
    }

    @Test func launchUsesTheConfiguredPrefix() {
        var config = Fixture.config
        config.idPrefix = "qa-"

        #expect(IdentityPanelMapper.launch(context: Fixture.context(config: config)).idPrefix == "qa-")
    }

    @Test func aliasNeedsAnID() {
        let desired = IdentityPanelMapper.launch(context: Fixture.context(settings: Fixture.settings(desired: "devhub-1")))
        let current = IdentityPanelMapper.launch(context: Fixture.context(settings: Fixture.settings(applied: "real")))

        #expect(desired.canEditAlias)
        #expect(desired.aliasPlaceholder == "a name for this ID")
        #expect(current.canEditAlias)
        #expect(current.aliasPlaceholder == "a name for the simulator's current ID")
    }

    @Test func aliasIsShownNextToTheID() {
        let aliases = ["devhub-3f9a1c2e": "Sam QA", "devhub-2": "Bob QA"]
        let context = Fixture.context(settings: Fixture.settings(desired: "devhub-2", applied: "devhub-3f9a1c2e"), aliases: aliases)

        let summary = IdentityPanelMapper.summary(context: context, mockState: nil)
        let model = panel(context)

        #expect(summary.deviceAlias == "Sam QA")
        #expect(summary.deviceID == "devhub-3f9a1c2e")
        #expect(summary.nextDeviceTag?.text == "next: Bob QA · devhub-2")
        #expect(model.deviceAlias == "Sam QA")
        #expect(model.deviceID == "devhub-3f9a1c2e")
    }

    @Test func cleanInstallNoteTexts() {
        var noCleaning = Fixture.config
        noCleaning.cleanInstallOnChange = false

        let same = IdentityPanelMapper.cleanInstallNote(context: Fixture.context(), cleanInstallIsOn: false)
        let on = IdentityPanelMapper.cleanInstallNote(context: Fixture.context(), cleanInstallIsOn: true)
        let needed = IdentityPanelMapper.cleanInstallNote(context: Fixture.context(settings: Fixture.settings(desired: "devhub-1")), cleanInstallIsOn: true)
        let off = IdentityPanelMapper.cleanInstallNote(context: Fixture.context(settings: Fixture.settings(desired: "devhub-1"), config: noCleaning), cleanInstallIsOn: false)

        #expect(same == CleanInstallNoteModel(
            icon: "info.circle",
            iconTint: .secondary,
            text: "Same ID as now: the app is updated in place and the session stays."
        ))
        #expect(on == CleanInstallNoteModel(
            icon: "exclamationmark.triangle.fill",
            iconTint: .orange,
            text: "Clean install is on: the next launch deletes the app and resets the simulator keychain first."
        ))
        #expect(needed == CleanInstallNoteModel(
            icon: "exclamationmark.triangle.fill",
            iconTint: .orange,
            text: "The app on this simulator has another ID: the next launch deletes the app, resets the simulator keychain and installs it again. The session is lost."
        ))
        #expect(off.text == "launch.identity.cleanInstallOnChange is off: the app is updated in place even when the ID changes.")
    }

    private func panel(_ context: IdentityContext, buildIsRunning: Bool = false, cleanInstallIsOn: Bool = false) -> IdentityPanelModel {
        IdentityPanelMapper.model(context: context, bundleID: "com.example.app", buildIsRunning: buildIsRunning, cleanInstallIsOn: cleanInstallIsOn)
    }

    @Test func aPhysicalDeviceHidesAttachAndSaysTheKeychainStays() {
        let device = Fixture.context(isPhysicalDevice: true)
        let needed = Fixture.context(settings: Fixture.settings(desired: "devhub-1"), isPhysicalDevice: true)

        let model = IdentityPanelMapper.model(context: device, bundleID: "com.example.app", buildIsRunning: false, cleanInstallIsOn: false)
        let on = IdentityPanelMapper.cleanInstallNote(context: device, cleanInstallIsOn: true)
        let reinstall = IdentityPanelMapper.cleanInstallNote(context: needed, cleanInstallIsOn: false)

        #expect(model.canAttach == false)
        #expect(IdentityPanelMapper.model(context: Fixture.context(), bundleID: "com.example.app", buildIsRunning: false, cleanInstallIsOn: false).canAttach)
        #expect(on.text == "Clean install is on: the next launch deletes the app and installs the last build again. The keychain of the device stays.")
        #expect(reinstall.text == "The app on this device has another ID: the next launch deletes the app and installs the last build again. The keychain of the device stays. The session is lost.")
    }
}
