import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct IdentityStoreTests {
    private let harness = StoreHarness(projects: [ProjectSample.identified])
    private let config = DeviceIdentityConfig.example
    private let simulator = SimulatorSample.booted
    private let installed = AppIdentity(isInstalled: true, version: "1.0", hasDebugHooks: true, lastDeviceID: "real-device")

    private var store: IdentityStore {
        harness.identity
    }

    private var savedSettings: [Simulator.ID: SimulatorIdentitySettings]? {
        harness.store.decode([Simulator.ID: SimulatorIdentitySettings].self, forKey: "simulators.identity")
    }

    // MARK: Persistence

    @Test func settingsAndSavedDeviceIDsAreRestored() {
        let saved = InMemoryKeyValueStore()
        let settings = SimulatorIdentitySettings(desiredDeviceID: "device-1", desiredEnvironment: "dev", appliedDeviceID: nil, hasApplied: false)
        saved.encode([simulator.id: settings], forKey: "simulators.identity")
        saved.set(["device-1"], forKey: "devhub.savedDeviceIDs")
        saved.encode(["device-1": "Sam QA"], forKey: "devhub.deviceIDAliases")

        let store = StoreHarness(projects: [ProjectSample.identified], store: saved).identity

        #expect(store.settings(for: simulator.id) == settings)
        #expect(store.savedDeviceIDs == ["device-1"])
        #expect(store.deviceIDAliases == ["device-1": "Sam QA"])
        #expect(store.alias(for: simulator.id) == "Sam QA")
    }

    @Test func settingsDefaultToEmpty() {
        #expect(store.settings(for: simulator.id) == SimulatorIdentitySettings(hasApplied: false))
    }

    @Test func setDesiredDeviceIDTrimsAndPersists() {
        store.setDesiredDeviceID(" device-1 ", for: simulator.id)

        #expect(store.settings(for: simulator.id).desiredDeviceID == "device-1")
        #expect(savedSettings?[simulator.id]?.desiredDeviceID == "device-1")

        store.setDesiredDeviceID("  ", for: simulator.id)

        #expect(store.settings(for: simulator.id).desiredDeviceID == nil)
    }

    @Test func setDesiredEnvironmentTreatsEmptyAsNil() {
        store.setDesiredEnvironment("dev", for: simulator.id)
        #expect(savedSettings?[simulator.id]?.desiredEnvironment == "dev")

        store.setDesiredEnvironment("", for: simulator.id)
        #expect(store.settings(for: simulator.id).desiredEnvironment == nil)
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

    @Test func withoutADesiredIDTheAliasNamesTheCurrentIDWithoutSavingIt() async {
        harness.spies.identity.readResult = installed
        await store.refresh(id: simulator.id)

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

    @Test func markAppliedRecordsTheDeviceID() {
        store.markApplied(id: simulator.id, deviceID: "device-1")

        #expect(store.settings(for: simulator.id).appliedDeviceID == "device-1")
        #expect(store.settings(for: simulator.id).hasApplied)
        #expect(savedSettings?[simulator.id]?.hasApplied == true)
    }

    // MARK: Reading

    @Test func aRefreshWithTheSameIdentityDoesNotNotifyViews() async {
        harness.spies.identity.readResult = installed
        await store.refresh(id: simulator.id)
        let probe = ObservationProbe { _ = store.identities }

        await store.refresh(id: simulator.id)

        #expect(probe.changed == false)
    }

    @Test func refreshReadsTheIdentity() async {
        harness.spies.identity.readResult = installed

        await store.refresh(id: simulator.id)

        #expect(store.identities[simulator.id] == installed)
        #expect(store.isInstalled(on: simulator.id))
        #expect(harness.spies.identity.calls == [.read(udid: simulator.id, config: config)])
    }

    @Test func refreshWithoutAnIdentityConfigDoesNothing() async {
        let harness = StoreHarness()

        await harness.identity.refresh(id: simulator.id)

        #expect(harness.spies.identity.calls.isEmpty)
        #expect(harness.identity.config == nil)
    }

    @Test func simulatorsChangedReadsWatchedSimulators() async throws {
        harness.spies.identity.readResult = installed
        harness.simulators.groups = SimulatorSample.groups
        harness.simulators.installedAppCounts = [SimulatorSample.pad.id: 1]
        _ = store

        harness.events.post(.simulatorsChanged)

        try await waitUntil { store.identities.count == 2 }
        #expect(Set(harness.spies.identity.calls) == [
            .read(udid: SimulatorSample.booted.id, config: config),
            .read(udid: SimulatorSample.pad.id, config: config),
        ])
    }

    @Test func projectChangedClearsIdentities() {
        store.identities = [simulator.id: installed]

        harness.events.post(.projectChanged)

        #expect(store.identities.isEmpty)
    }

    @Test func buildStartedRemembersTheDesiredDeviceID() {
        store.setDesiredDeviceID("device-1", for: simulator.id)

        harness.events.post(.buildStarted(simulatorID: simulator.id))

        #expect(store.savedDeviceIDs == ["device-1"])
        #expect(store.isApplying(simulator.id) == false)
    }

    @Test func buildFinishedWithALaunchedDeviceIDMarksItApplied() {
        _ = store
        harness.events.post(.buildFinished(simulatorID: simulator.id, launchedDeviceID: .some("device-1")))

        #expect(store.settings(for: simulator.id).appliedDeviceID == "device-1")
        #expect(store.settings(for: simulator.id).hasApplied)
    }

    @Test func buildFinishedWithTheRealDeviceIDMarksNilApplied() {
        _ = store
        harness.events.post(.buildFinished(simulatorID: simulator.id, launchedDeviceID: .some(nil)))

        #expect(store.settings(for: simulator.id).appliedDeviceID == nil)
        #expect(store.settings(for: simulator.id).hasApplied)
    }

    @Test func buildFinishedWithoutALaunchChangesNothing() {
        _ = store
        harness.events.post(.buildFinished(simulatorID: simulator.id, launchedDeviceID: nil))

        #expect(store.settings(for: simulator.id).hasApplied == false)
    }

    // MARK: Lookups

    @Test func buildIdentityCarriesTheDesiredValues() {
        store.setDesiredDeviceID("device-1", for: simulator.id)
        store.setDesiredEnvironment("dev", for: simulator.id)

        let identity = store.buildIdentity(for: simulator.id)

        #expect(identity?.config == config)
        #expect(identity?.deviceID == "device-1")
        #expect(identity?.environment == "dev")
        #expect(StoreHarness().identity.buildIdentity(for: simulator.id) == nil)
    }

    @Test func needsCleanInstallComparesTheInstalledDeviceID() {
        #expect(store.needsCleanInstall(id: simulator.id) == false)

        store.identities[simulator.id] = installed
        store.setDesiredDeviceID("device-1", for: simulator.id)
        #expect(store.needsCleanInstall(id: simulator.id))

        store.setDesiredDeviceID("real-device", for: simulator.id)
        #expect(store.needsCleanInstall(id: simulator.id) == false)
    }

    // MARK: Launch

    @Test func launchInstalledAppAppliesTheSettings() async throws {
        store.setDesiredDeviceID("device-1", for: simulator.id)
        store.setDesiredEnvironment("dev", for: simulator.id)

        store.launchInstalledApp(on: simulator, attachDebugger: false, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        #expect(store.isApplying(simulator.id))
        #expect(store.savedDeviceIDs == ["device-1"])
        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.spies.identity.calls == [
            .setEnvironment("dev", udid: simulator.id, config: config),
            .launch(udid: simulator.id, config: config, deviceID: "device-1", waitForDebugger: false, environment: [:]),
        ])
        #expect(store.settings(for: simulator.id).appliedDeviceID == "device-1")
        #expect(store.settings(for: simulator.id).hasApplied)
        #expect(harness.lastActivity?.title == "Launched on iPhone 17")
        #expect(harness.lastActivity?.detail == "device ID device-1 · dev")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func launchInstalledAppCanForceACleanInstall() async throws {
        store.launchInstalledApp(on: simulator, attachDebugger: false, forceCleanInstall: true, projectPath: ProjectSample.path, fallbackAppPath: "/tmp/App.app")

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.spies.identity.calls == [
            .cleanInstall(udid: simulator.id, config: config, fallbackAppPath: "/tmp/App.app"),
            .launch(udid: simulator.id, config: config, deviceID: nil, waitForDebugger: false, environment: [:]),
        ])
        #expect(harness.lastActivity?.detail == "real device ID · clean install")
    }

    @Test func launchInstalledAppAttachesXcode() async throws {
        harness.spies.identity.launchResult = .success(42)

        store.launchInstalledApp(on: simulator, attachDebugger: true, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.spies.identity.calls == [.launch(udid: simulator.id, config: config, deviceID: nil, waitForDebugger: true, environment: [:])])
        #expect(harness.spies.attacher.calls == [.attach(pid: 42, simulatorUDID: simulator.id, projectPath: ProjectSample.path)])
        #expect(harness.lastActivity?.detail == "real device ID · Xcode attached")
    }

    @Test func launchInstalledAppAsksForAccessibilityFirst() {
        harness.spies.attacher.isTrusted = false

        store.launchInstalledApp(on: simulator, attachDebugger: true, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        #expect(store.isApplying(simulator.id) == false)
        #expect(harness.spies.attacher.calls == [.requestTrust])
        #expect(harness.lastActivity?.title == "Allow DevHub in Accessibility")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aFailedLaunchLogsAndDoesNotMarkApplied() async throws {
        harness.spies.identity.launchResult = .failure(TestError.scripted("boom"))

        store.launchInstalledApp(on: simulator, attachDebugger: false, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.lastActivity?.title == "Could not apply device settings: iPhone 17")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(store.settings(for: simulator.id).hasApplied == false)
    }

    @Test func aFailedAttachStillMarksApplied() async throws {
        store.launchInstalledApp(on: simulator, attachDebugger: true, forceCleanInstall: false, projectPath: ProjectSample.path, fallbackAppPath: nil)

        try await waitUntil { store.isApplying(simulator.id) == false }
        #expect(harness.lastActivity?.title == "Could not apply device settings: iPhone 17")
        #expect(store.settings(for: simulator.id).hasApplied)
    }
}
