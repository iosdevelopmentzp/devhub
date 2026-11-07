import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct IdentityStoreTests {
    private let harness = StoreHarness()
    private let simulator = SimulatorSample.booted
    private let installed = InstalledApp(isInstalled: true, version: "1.0", hasIdentityHook: true, keepsIdentity: false, storedProfileID: nil)
    private let bundleID = ProjectSample.app.bundleID

    private var store: IdentityStore {
        harness.identity
    }

    private var savedSettings: [Simulator.ID: SimulatorLaunchSettings]? {
        harness.store.decode([Simulator.ID: SimulatorLaunchSettings].self, forKey: "simulators.launchSettings")
    }

    private var lastLaunch: SpySimulatorRepository.Call? {
        harness.spies.simulators.calls.last { if case .launch = $0 { true } else { false } }
    }

    private func loadConfig(_ resolved: ResolvedConfig = LaunchConfigSample.resolved()) async {
        harness.spies.config.loadResult = resolved
        await harness.config.reload()
    }

    private func record(identity: String?, profileID: String? = nil, baseURL: String? = nil) -> LaunchRecord {
        LaunchRecord(bundleID: nil, profileID: profileID, identity: identity, baseURL: baseURL, date: Date(timeIntervalSince1970: 0))
    }

    // MARK: Persistence

    @Test func settingsAndSavedDeviceIDsAreRestored() {
        let saved = InMemoryKeyValueStore()
        let settings = SimulatorLaunchSettings(desiredIdentity: "device-1", appliedIdentity: nil, hasApplied: false, lastLaunch: nil)
        saved.encode([simulator.id: settings], forKey: "simulators.launchSettings")
        saved.set(["device-1"], forKey: "devhub.savedDeviceIDs")
        saved.encode(["device-1": "Sam QA"], forKey: "devhub.deviceIDAliases")

        let store = StoreHarness(store: saved).identity

        #expect(store.settings(for: simulator.id) == settings)
        #expect(store.savedDeviceIDs == ["device-1"])
        #expect(store.deviceIDAliases == ["device-1": "Sam QA"])
        #expect(store.alias(for: simulator.id) == "Sam QA")
    }

    @Test func settingsDefaultToEmpty() {
        #expect(store.settings(for: simulator.id) == .empty)
    }

    @Test func setDesiredDeviceIDTrimsAndPersists() {
        store.setDesiredDeviceID(" device-1 ", for: simulator.id)

        #expect(store.settings(for: simulator.id).desiredIdentity == "device-1")
        #expect(savedSettings?[simulator.id]?.desiredIdentity == "device-1")

        store.setDesiredDeviceID("  ", for: simulator.id)

        #expect(store.settings(for: simulator.id).desiredIdentity == nil)
    }

    @Test func rememberDesiredDeviceIDAddsItOnce() {
        store.setDesiredDeviceID("device-1", for: simulator.id)

        store.rememberDesiredDeviceID(for: simulator.id)
        store.rememberDesiredDeviceID(for: simulator.id)

        #expect(store.savedDeviceIDs == ["device-1"])
        #expect(harness.store.strings(forKey: "devhub.savedDeviceIDs") == ["device-1"])
    }

    @Test func forgetSavedDeviceIDRemovesIt() {
        store.setDesiredDeviceID("device-1", for: simulator.id)
        store.rememberDesiredDeviceID(for: simulator.id)

        store.forgetSavedDeviceID("device-1")

        #expect(store.savedDeviceIDs.isEmpty)
        #expect(harness.store.strings(forKey: "devhub.savedDeviceIDs") == [])
    }

    @Test func setDesiredAliasNamesTheDesiredDeviceIDAndSavesIt() {
        store.setAlias("Sam QA", for: simulator.id)
        #expect(store.deviceIDAliases.isEmpty)

        store.setDesiredDeviceID("device-1", for: simulator.id)
        store.setAlias("Sam QA", for: simulator.id)

        #expect(store.alias(for: simulator.id) == "Sam QA")
        #expect(store.savedDeviceIDs == ["device-1"])
        #expect(harness.store.decode([String: String].self, forKey: "devhub.deviceIDAliases") == ["device-1": "Sam QA"])

        store.setAlias("  ", for: simulator.id)

        #expect(store.deviceIDAliases.isEmpty)
        #expect(store.savedDeviceIDs == ["device-1"])
    }

    @Test func withoutADesiredIDTheAliasNamesTheReportedIDWithoutSavingIt() {
        _ = store
        harness.events.post(.appStateReported(simulatorID: simulator.id, report: AppStateReport(identity: "real-device", profile: nil, host: nil, user: nil, version: nil)))

        store.setAlias("Real one", for: simulator.id)

        #expect(store.alias(for: simulator.id) == "Real one")
        #expect(store.deviceIDAliases == ["real-device": "Real one"])
        #expect(store.savedDeviceIDs.isEmpty)

        store.setDesiredDeviceID("device-1", for: simulator.id)
        #expect(store.alias(for: simulator.id) == "")
    }

    @Test func forgetSavedDeviceIDRemovesItsAlias() {
        store.setDesiredDeviceID("device-1", for: simulator.id)
        store.setAlias("Sam QA", for: simulator.id)

        store.forgetSavedDeviceID("device-1")

        #expect(store.deviceIDAliases.isEmpty)
        #expect(store.alias(for: simulator.id) == "")
    }

    @Test func newIdentityUsesTheConfiguredPrefix() async {
        #expect(store.newIdentity().hasPrefix("devhub-"))

        var identity = LaunchConfigSample.identity
        identity.idPrefix = "qa-"
        await loadConfig(LaunchConfigSample.resolved(identity: identity))

        #expect(store.newIdentity().hasPrefix("qa-"))
    }

    // MARK: Reading

    @Test func refreshInspectsTheAppWithTheIdentityAndTheProfileStorage() async {
        var staging = LaunchConfigSample.staging
        staging.storage = ProfileStorage(suite: "group.com.example.app", key: "environment")
        await loadConfig(LaunchConfigSample.resolved(profiles: [staging]))
        harness.spies.launcher.inspectResult = installed

        await store.refresh(id: simulator.id)

        #expect(store.apps[simulator.id] == installed)
        #expect(store.isInstalled(on: simulator.id))
        #expect(harness.spies.launcher.calls == [.inspect(udid: simulator.id, bundleID: bundleID, identity: LaunchConfigSample.identity, storage: staging.storage)])
    }

    @Test func aRefreshWithTheSameAppDoesNotNotifyViews() async {
        await loadConfig()
        harness.spies.launcher.inspectResult = installed
        await store.refresh(id: simulator.id)
        let probe = ObservationProbe { _ = store.apps }

        await store.refresh(id: simulator.id)

        #expect(probe.changed == false)
    }

    @Test func refreshWithoutAnIdentityConfigDoesNothing() async {
        await store.refresh(id: simulator.id)

        #expect(harness.spies.launcher.calls.isEmpty)
        #expect(store.identityConfig == nil)
        #expect(store.context(for: simulator.id) == nil)
    }

    @Test func simulatorsChangedInspectsWatchedSimulators() async throws {
        await loadConfig()
        harness.spies.launcher.inspectResult = installed
        harness.simulators.groups = SimulatorSample.groups
        harness.simulators.installedAppCounts = [SimulatorSample.pad.id: 1]
        _ = store

        harness.events.post(.simulatorsChanged)

        try await waitUntil { store.apps.count == 2 }
        #expect(Set(harness.spies.launcher.calls) == [
            .inspect(udid: SimulatorSample.booted.id, bundleID: bundleID, identity: LaunchConfigSample.identity, storage: nil),
            .inspect(udid: SimulatorSample.pad.id, bundleID: bundleID, identity: LaunchConfigSample.identity, storage: nil),
        ])
    }

    @Test func projectChangedClearsAppsAndReports() {
        store.apps = [simulator.id: installed]
        harness.events.post(.appStateReported(simulatorID: simulator.id, report: AppStateReport(identity: "a", profile: nil, host: nil, user: nil, version: nil)))

        harness.events.post(.projectChanged)

        #expect(store.apps.isEmpty)
        #expect(store.reports.isEmpty)
    }

    @Test func aStateReportBecomesTheActualIdentity() {
        _ = store
        let report = AppStateReport(identity: "reported", profile: "staging", host: nil, user: nil, version: nil)

        harness.events.post(.appStateReported(simulatorID: simulator.id, report: report))

        #expect(store.reports[simulator.id] == report)
        #expect(store.actualIdentity(for: simulator.id) == "reported")
    }

    @Test func buildStartedRemembersTheDesiredDeviceID() {
        store.setDesiredDeviceID("device-1", for: simulator.id)

        harness.events.post(.buildStarted(simulatorID: simulator.id))

        #expect(store.savedDeviceIDs == ["device-1"])
        #expect(store.isApplying(simulator.id) == false)
    }

    @Test func buildFinishedWithALaunchRecordsIt() {
        _ = store
        let launch = record(identity: "device-1", profileID: "staging")

        harness.events.post(.buildFinished(simulatorID: simulator.id, launch: launch))

        #expect(store.settings(for: simulator.id).appliedIdentity == "device-1")
        #expect(store.settings(for: simulator.id).hasApplied)
        #expect(store.settings(for: simulator.id).lastLaunch == launch)
        #expect(savedSettings?[simulator.id]?.lastLaunch == launch)
    }

    @Test func aLaunchWithoutAnIDRecordsTheOwnID() {
        _ = store
        harness.events.post(.appLaunched(simulatorID: simulator.id, launch: record(identity: nil)))

        #expect(store.settings(for: simulator.id).appliedIdentity == nil)
        #expect(store.settings(for: simulator.id).hasApplied)
    }

    @Test func buildFinishedWithoutALaunchChangesNothing() {
        _ = store
        harness.events.post(.buildFinished(simulatorID: simulator.id, launch: nil))

        #expect(store.settings(for: simulator.id).hasApplied == false)
    }

    // MARK: Lookups

    @Test func planCarriesTheIdentityTheProfileAndTheBaseURLVariable() async {
        await loadConfig()

        let plan = store.plan(for: simulator.id, profile: LaunchConfigSample.staging, identity: "device-1")

        #expect(plan == LaunchPlan(profile: LaunchConfigSample.staging, identityConfig: LaunchConfigSample.identity, identity: "device-1", baseURLVariable: "APP_BASE_URL"))
    }

    @Test func needsCleanInstallComparesTheActualID() async {
        await loadConfig()
        #expect(store.needsCleanInstall(id: simulator.id) == false)

        store.apps[simulator.id] = installed
        harness.events.post(.appStateReported(simulatorID: simulator.id, report: AppStateReport(identity: "real-device", profile: nil, host: nil, user: nil, version: nil)))
        store.setDesiredDeviceID("device-1", for: simulator.id)
        #expect(store.needsCleanInstall(id: simulator.id))
        #expect(store.context(for: simulator.id)?.needsCleanInstall == true)

        store.setDesiredDeviceID("real-device", for: simulator.id)
        #expect(store.needsCleanInstall(id: simulator.id) == false)
    }

    // MARK: Launch

    @Test func launchInstalledAppLaunchesWithTheIdentityAndTheProfile() async throws {
        await loadConfig()
        store.setDesiredDeviceID("device-1", for: simulator.id)

        store.launchInstalledApp(on: simulator, profile: LaunchConfigSample.staging, attachDebugger: false, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        #expect(store.isApplying(simulator.id))
        #expect(store.savedDeviceIDs == ["device-1"])
        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.spies.launcher.calls.isEmpty)
        #expect(lastLaunch == .launch(udid: simulator.id, bundleID: bundleID, waitForDebugger: false, environment: ["API_ENV": "staging", "APP_DEVICE_ID": "device-1"]))
        #expect(store.settings(for: simulator.id).appliedIdentity == "device-1")
        #expect(store.settings(for: simulator.id).lastLaunch?.profileID == "staging")
        #expect(harness.lastActivity?.title == "Launched on iPhone 17")
        #expect(harness.lastActivity?.detail == "ID device-1 · Staging")
        #expect(harness.lastActivity?.outcome == .success)
        #expect(harness.postedLabels.contains("appLaunched(sim-booted, staging device-1)"))
    }

    @Test func launchInstalledAppCanForceACleanInstall() async throws {
        store.launchInstalledApp(on: simulator, profile: nil, attachDebugger: false, forceCleanInstall: true, projectPath: ProjectSample.path, fallbackAppPath: "/tmp/App.app")

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.spies.launcher.calls == [.cleanInstall(udid: simulator.id, bundleID: bundleID, fallbackAppPath: "/tmp/App.app")])
        #expect(harness.lastActivity?.detail == "own ID · clean install")
    }

    @Test func aProfileWithCleanInstallReinstalls() async throws {
        var profile = LaunchConfigSample.staging
        profile.cleanInstall = true

        store.launchInstalledApp(on: simulator, profile: profile, attachDebugger: false, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.spies.launcher.calls == [.cleanInstall(udid: simulator.id, bundleID: bundleID, fallbackAppPath: nil)])
    }

    @Test func launchInstalledAppAttachesXcode() async throws {
        harness.spies.simulators.launchResult = .success(42)

        store.launchInstalledApp(on: simulator, profile: nil, attachDebugger: true, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(lastLaunch == .launch(udid: simulator.id, bundleID: bundleID, waitForDebugger: true, environment: [:]))
        #expect(harness.spies.attacher.calls == [.attach(pid: 42, simulatorUDID: simulator.id, projectPath: ProjectSample.path, container: nil)])
        #expect(harness.lastActivity?.detail == "own ID · Xcode attached")
    }

    @Test func attachOpensTheContainerOfTheConfig() async throws {
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(xcode: XcodeConfig(container: "App.xcworkspace")), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
        harness.spies.simulators.launchResult = .success(42)

        store.launchInstalledApp(on: simulator, profile: nil, attachDebugger: true, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.spies.attacher.calls == [.attach(pid: 42, simulatorUDID: simulator.id, projectPath: ProjectSample.path, container: "App.xcworkspace")])
    }

    @Test func launchInstalledAppAsksForAccessibilityFirst() {
        harness.spies.attacher.isTrusted = false

        store.launchInstalledApp(on: simulator, profile: nil, attachDebugger: true, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        #expect(store.isApplying(simulator.id) == false)
        #expect(harness.spies.attacher.calls == [.requestTrust])
        #expect(harness.lastActivity?.title == "Allow DevHub in Accessibility")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aFailedLaunchLogsAndRecordsNothing() async throws {
        harness.spies.simulators.launchResult = .failure(TestError.scripted("boom"))

        store.launchInstalledApp(on: simulator, profile: nil, attachDebugger: false, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.lastActivity?.title == "Could not launch on iPhone 17")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(store.settings(for: simulator.id).hasApplied == false)
    }

    @Test func aFailedAttachStillRecordsTheLaunch() async throws {
        store.launchInstalledApp(on: simulator, profile: nil, attachDebugger: true, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.lastActivity?.title == "Could not launch on iPhone 17")
        #expect(store.settings(for: simulator.id).hasApplied)
    }

    @Test func bundleIDFollowsTheLastLaunchWhenTheProjectKnowsIt() async {
        let resolved = LaunchConfigSample.resolved()
        var project = resolved.project
        project.xcode = XcodeConfig(bundleIDs: ["Beta": "com.example.app.beta"])
        await loadConfig(ResolvedConfig(project: project, actions: [], tabs: [], issues: [], layers: []))
        #expect(store.bundleID(for: simulator.id) == bundleID)

        harness.events.post(.appLaunched(simulatorID: simulator.id, launch: LaunchRecord(bundleID: "com.example.app.beta", profileID: nil, identity: nil, baseURL: nil, date: .now)))
        #expect(store.bundleID(for: simulator.id) == "com.example.app.beta")

        harness.events.post(.appLaunched(simulatorID: simulator.id, launch: LaunchRecord(bundleID: "com.example.other", profileID: nil, identity: nil, baseURL: nil, date: .now)))
        #expect(store.bundleID(for: simulator.id) == bundleID)
    }

    @Test func refreshOnADeviceInspectsThroughDevicectlWithTheLastBuild() async {
        await loadConfig()
        harness.simulators.groups = [SimulatorGroup(runtime: SimulatorGroup.devicesTitle, simulators: [SimulatorSample.device])]
        harness.spies.build.lastBuiltAppPathResult = "/derived/App.app"
        harness.spies.devices.inspectResult = installed
        _ = harness.build

        await store.refresh(id: SimulatorSample.device.id)

        #expect(store.apps[SimulatorSample.device.id] == installed)
        #expect(harness.spies.launcher.calls.isEmpty)
        #expect(harness.spies.devices.calls == [.inspect(udid: SimulatorSample.device.id, bundleID: bundleID, identity: LaunchConfigSample.identity, storage: nil, localAppPath: "/derived/App.app")])
        #expect(store.context(for: SimulatorSample.device.id)?.isPhysicalDevice == true)
        #expect(harness.spies.build.lastBuiltAppPathPlatforms == [true])
    }
}
