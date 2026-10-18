import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct MockServerStoreTests {
    private let harness = StoreHarness()
    private let udid = SimulatorSample.booted.id
    private let staging = URL(string: "https://api.staging.example.com")!
    private let dev = URL(string: "https://api.dev.example.com")!
    private let stub = ["API_ENV": "staging", "APP_BASE_URL": "http://127.0.0.1:52001"]

    private var store: MockServerStore {
        harness.mockServer
    }

    private var lastLaunch: SpySimulatorRepository.Call? {
        harness.spies.simulators.calls.last { if case .launch = $0 { true } else { false } }
    }

    private func loadConfig(_ resolved: ResolvedConfig = LaunchConfigSample.resolved()) async {
        harness.spies.config.loadResult = resolved
        await harness.config.reload()
    }

    private func applyAndWait() async throws {
        if harness.config.config.launch == nil {
            await loadConfig()
        }
        store.apply(on: udid)
        try await waitUntil { store.isApplying(udid) == false }
    }

    private func loadSets() async {
        harness.spies.mockSets.listResult = .success([MockSetSample.vip, MockSetSample.empty])
        await harness.mockSets.load()
    }

    // MARK: Settings

    @Test func modeAndSetArePersistedPerSimulator() {
        let saved = InMemoryKeyValueStore()
        let first = StoreHarness(store: saved).mockServer
        first.setMode(.mock, for: udid)
        first.selectSet(MockSetSample.vip.id, for: udid)
        first.setMode(.passthrough, for: "other")

        let restored = StoreHarness(store: saved).mockServer

        #expect(restored.settings(for: udid) == MockSimulatorSettings(mode: .mock, setID: MockSetSample.vip.id))
        #expect(restored.settings(for: "other") == MockSimulatorSettings(mode: .passthrough, setID: nil))
        #expect(restored.settings(for: "unknown") == .off)
        #expect(saved.data(forKey: "network.mock.settings") != nil)
    }

    @Test func needsApplyComparesTheWishWithTheRunningServer() async throws {
        await loadConfig()
        #expect(store.needsApply(udid) == false)

        store.setMode(.passthrough, for: udid)
        #expect(store.needsApply(udid))

        try await applyAndWait()
        #expect(store.needsApply(udid) == false)
    }

    // MARK: Apply

    @Test func applyPassthroughStartsTheServerAndRelaunchesWithTheStubURL() async throws {
        await loadConfig()
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.start(udid: udid, upstream: staging, rules: [])))
        #expect(lastLaunch == .launch(udid: udid, bundleID: ProjectSample.app.bundleID, waitForDebugger: false, environment: stub))
        #expect(store.states[udid] == MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api.staging.example.com", status: .running(port: 52001)))
        #expect(store.isIntercepting(udid))
        #expect(store.errors[udid] == nil)
        #expect(harness.lastActivity?.title == "Passthrough on \(udid)")
        #expect(harness.identity.settings(for: udid).lastLaunch?.baseURL == "http://127.0.0.1:52001")
    }

    @Test func applyUsesTheStoredProfileAndTheActualIdentity() async throws {
        await loadConfig()
        harness.identity.apps[udid] = InstalledApp(isInstalled: true, version: "1", hasIdentityHook: true, keepsIdentity: false, storedProfileID: "dev")
        harness.events.post(.appStateReported(simulatorID: udid, report: AppStateReport(identity: "QA-DEVICE", profile: nil, host: nil, user: nil, version: nil)))
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.start(udid: udid, upstream: dev, rules: [])))
        #expect(lastLaunch == .launch(udid: udid, bundleID: ProjectSample.app.bundleID, waitForDebugger: false, environment: ["APP_DEVICE_ID": "QA-DEVICE", "APP_BASE_URL": "http://127.0.0.1:52001"]))
    }

    @Test func theReportedProfileWinsOverTheStoredOne() async throws {
        await loadConfig()
        harness.identity.apps[udid] = InstalledApp(isInstalled: true, version: "1", hasIdentityHook: true, keepsIdentity: false, storedProfileID: "staging")
        harness.events.post(.appStateReported(simulatorID: udid, report: AppStateReport(identity: nil, profile: "Dev", host: nil, user: nil, version: nil)))
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.start(udid: udid, upstream: dev, rules: [])))
    }

    @Test func applyUsesTheProfileOfTheRunBar() async throws {
        await loadConfig()
        harness.build.setProfile("dev")
        harness.build.selectTarget(id: udid)
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.start(udid: udid, upstream: dev, rules: [])))
    }

    @Test func applyMockSendsTheRulesOfTheChosenSet() async throws {
        await loadConfig()
        await loadSets()
        store.setMode(.mock, for: udid)
        store.selectSet(MockSetSample.vip.id, for: udid)

        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.start(udid: udid, upstream: staging, rules: MockSetSample.vip.rules)))
        #expect(store.states[udid]?.setID == MockSetSample.vip.id)
    }

    @Test func productionIsRefusedAndShownInline() async throws {
        await loadConfig()
        harness.identity.apps[udid] = InstalledApp(isInstalled: true, version: "1", hasIdentityHook: true, keepsIdentity: false, storedProfileID: "production")
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(store.errors[udid] == MockServerError.productionRefused(profile: "Production").localizedDescription)
        #expect(store.states[udid] == nil)
        #expect(harness.spies.simulators.calls.isEmpty)
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func projectWithoutTheBaseURLVariableShowsWhatIsMissing() async throws {
        await loadConfig(LaunchConfigSample.resolved(baseURLVariable: nil))
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(store.errors[udid] == MockServerError.disabled.localizedDescription)
    }

    @Test func projectWithoutProfilesShowsWhatIsMissing() async throws {
        await loadConfig(LaunchConfigSample.resolved(profiles: nil))
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(store.errors[udid] == MockServerError.noProfile.localizedDescription)
    }

    @Test func turningOffStopsTheServerAndRelaunchesPlain() async throws {
        await loadConfig()
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()

        store.setMode(.off, for: udid)
        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.stop(udid: udid)))
        #expect(lastLaunch == .launch(udid: udid, bundleID: ProjectSample.app.bundleID, waitForDebugger: false, environment: ["API_ENV": "staging"]))
        #expect(store.states[udid] == nil)
        #expect(store.isIntercepting(udid) == false)
    }

    @Test func applyRemembersTheUpstreamAndOffForgetsIt() async throws {
        await loadConfig()
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()
        #expect(store.settings(for: udid).upstream == staging.absoluteString)

        store.setMode(.off, for: udid)
        try await applyAndWait()
        #expect(store.settings(for: udid).upstream == nil)
    }

    @Test func aLaunchOnAnotherProfileUpdatesTheServerState() async throws {
        await loadConfig()
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()
        await harness.spies.mockServer.retarget(udid: udid, upstream: dev)

        harness.events.post(.appLaunched(simulatorID: udid, launch: nil))

        try await waitUntil { store.states[udid]?.upstreamHost == "api.dev.example.com" }
        #expect(store.settings(for: udid).upstream == dev.absoluteString)
    }

    @Test func aLaunchThatStoppedTheServerClearsTheState() async throws {
        await loadConfig()
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()
        await harness.spies.mockServer.stop(udid: udid)

        harness.events.post(.buildFinished(simulatorID: udid, launch: nil))

        try await waitUntil { store.states[udid] == nil }
    }

    @Test func restoreServersStartsTheSavedOnesWithoutRelaunching() async throws {
        await loadSets()
        let saved = InMemoryKeyValueStore()
        saved.encode(
            [
                udid: MockSimulatorSettings(mode: .mock, setID: MockSetSample.vip.id, upstream: MockSetSample.qa.absoluteString),
                "off": MockSimulatorSettings(mode: .off, setID: nil, upstream: MockSetSample.qa.absoluteString),
                "no-upstream": MockSimulatorSettings(mode: .passthrough, setID: nil, upstream: nil),
            ],
            forKey: "network.mock.settings"
        )
        let restored = StoreHarness(store: saved)
        restored.spies.mockSets.listResult = .success([MockSetSample.vip])
        await restored.mockSets.load()

        restored.mockServer.restoreServers()

        try await waitUntil { restored.mockServer.states[udid] != nil }
        #expect(restored.spies.mockServer.calls == [.start(udid: udid, upstream: MockSetSample.qa, rules: MockSetSample.vip.rules)])
        #expect(restored.mockServer.states[udid] == MockServerState(mode: .mock, setID: MockSetSample.vip.id, upstreamHost: "api-qa.example.com", status: .running(port: 52001)))
        #expect(restored.spies.simulators.calls.isEmpty)
        #expect(restored.lastActivity?.title == "Mock servers restored: 1")
    }

    // MARK: Traffic

    @Test func exchangesFromTheServerAreCollectedPerSimulator() async throws {
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()

        harness.spies.mockServer.emit(NetworkRequestSample.ok, udid: udid)

        try await waitUntil { store.exchanges(for: udid) == [NetworkRequestSample.ok] }
        #expect(store.exchanges(for: "other").isEmpty)
        store.clearExchanges(for: udid)
        #expect(store.exchanges(for: udid).isEmpty)
    }

    @Test func exchangesAreCappedAtTheLimit() {
        for id in 0..<(MockServerStore.maxExchanges + 5) {
            store.receive(NetworkRequestSample.make(id: id, method: "GET", path: "/x", statusCode: 200, duration: nil, isFailure: false), for: udid)
        }

        #expect(store.exchanges(for: udid).count == MockServerStore.maxExchanges)
        #expect(store.exchanges(for: udid).first?.id == 5)
    }

    // MARK: Events

    @Test func editingTheRunningSetPushesTheNewRules() async throws {
        await loadSets()
        store.setMode(.mock, for: udid)
        store.selectSet(MockSetSample.vip.id, for: udid)
        try await applyAndWait()

        harness.mockSets.toggleRule(id: MockSetSample.ruleID, in: MockSetSample.vip.id)

        let updated = try #require(harness.mockSets.set(id: MockSetSample.vip.id)?.rules)
        try await waitUntil { harness.spies.mockServer.calls.contains(.update(udid: udid, rules: updated)) }
        #expect(updated.first?.isEnabled == false)
    }

    @Test func editingAnotherSetDoesNotTouchTheServer() async throws {
        await loadSets()
        store.setMode(.mock, for: udid)
        store.selectSet(MockSetSample.vip.id, for: udid)
        try await applyAndWait()

        harness.mockSets.addRule(to: MockSetSample.empty.id)
        await harness.settle()

        #expect(harness.spies.mockServer.calls.contains { if case .update = $0 { true } else { false } } == false)
    }

    @Test func projectChangeStopsEveryServer() async throws {
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()

        harness.events.post(.projectChanged)

        #expect(store.states.isEmpty)
        try await waitUntil { harness.spies.mockServer.calls.contains(.stop(udid: udid)) }
    }
}
