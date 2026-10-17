import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct MockServerStoreTests {
    private let harness = StoreHarness(projects: [ProjectSample.identified])
    private let udid = SimulatorSample.booted.id
    private let stub = ["DEVHUB_BASE_URL": "http://127.0.0.1:52001"]

    private var store: MockServerStore {
        harness.mockServer
    }

    private func applyAndWait() async throws {
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
        let first = StoreHarness(projects: [ProjectSample.identified], store: saved).mockServer
        first.setMode(.mock, for: udid)
        first.selectSet(MockSetSample.vip.id, for: udid)
        first.setMode(.passthrough, for: "other")

        let restored = StoreHarness(projects: [ProjectSample.identified], store: saved).mockServer

        #expect(restored.settings(for: udid) == MockSimulatorSettings(mode: .mock, setID: MockSetSample.vip.id))
        #expect(restored.settings(for: "other") == MockSimulatorSettings(mode: .passthrough, setID: nil))
        #expect(restored.settings(for: "unknown") == .off)
        #expect(saved.data(forKey: "network.mock.settings") != nil)
    }

    @Test func needsApplyComparesTheWishWithTheRunningServer() async throws {
        #expect(store.needsApply(udid) == false)

        store.setMode(.passthrough, for: udid)
        #expect(store.needsApply(udid))

        try await applyAndWait()
        #expect(store.needsApply(udid) == false)
    }

    // MARK: Apply

    @Test func applyPassthroughStartsTheServerAndRelaunchesWithTheStubURL() async throws {
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.start(udid: udid, upstream: MockSetSample.qa, rules: [])))
        #expect(harness.spies.identity.calls == [.launch(udid: udid, config: .example, deviceID: nil, waitForDebugger: false, environment: stub)])
        #expect(store.states[udid] == MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api-qa.example.com", status: .running(port: 52001)))
        #expect(store.isIntercepting(udid))
        #expect(store.errors[udid] == nil)
        #expect(harness.lastActivity?.title == "Passthrough on \(udid)")
    }

    @Test func applyUsesTheStoredEnvironmentAndTheAppliedDeviceID() async throws {
        harness.identity.identities[udid] = AppIdentity(isInstalled: true, version: "1", hasDebugHooks: true, storedEnvironment: "dev")
        harness.identity.markApplied(id: udid, deviceID: "QA-DEVICE")
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.start(udid: udid, upstream: MockSetSample.dev, rules: [])))
        #expect(harness.spies.identity.calls == [.launch(udid: udid, config: .example, deviceID: "QA-DEVICE", waitForDebugger: false, environment: stub)])
    }

    @Test func applyMockSendsTheRulesOfTheChosenSet() async throws {
        await loadSets()
        store.setMode(.mock, for: udid)
        store.selectSet(MockSetSample.vip.id, for: udid)

        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.start(udid: udid, upstream: MockSetSample.qa, rules: MockSetSample.vip.rules)))
        #expect(store.states[udid]?.setID == MockSetSample.vip.id)
    }

    @Test func prodIsRefusedAndShownInline() async throws {
        harness.identity.identities[udid] = AppIdentity(isInstalled: true, version: "1", hasDebugHooks: true, storedEnvironment: "prod")
        store.setMode(.passthrough, for: udid)

        try await applyAndWait()

        #expect(store.errors[udid] == MockServerError.prodNotSupported.localizedDescription)
        #expect(store.states[udid] == nil)
        #expect(harness.spies.identity.calls.isEmpty)
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func projectWithoutIdentityShowsWhatIsMissing() async throws {
        let plain = StoreHarness()
        plain.mockServer.setMode(.passthrough, for: udid)

        plain.mockServer.apply(on: udid)
        try await waitUntil { plain.mockServer.isApplying(udid) == false }

        #expect(plain.mockServer.errors[udid] == MockServerError.noIdentityConfig.localizedDescription)
    }

    @Test func turningOffStopsTheServerAndRelaunchesPlain() async throws {
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()

        store.setMode(.off, for: udid)
        try await applyAndWait()

        #expect(harness.spies.mockServer.calls.contains(.stop(udid: udid)))
        #expect(harness.spies.identity.calls.last == .launch(udid: udid, config: .example, deviceID: nil, waitForDebugger: false, environment: [:]))
        #expect(store.states[udid] == nil)
        #expect(store.isIntercepting(udid) == false)
    }

    @Test func applyRemembersTheUpstreamAndOffForgetsIt() async throws {
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()
        #expect(store.settings(for: udid).upstream == MockSetSample.qa.absoluteString)

        store.setMode(.off, for: udid)
        try await applyAndWait()
        #expect(store.settings(for: udid).upstream == nil)
    }

    @Test func aLaunchOnAnotherEnvironmentUpdatesTheServerState() async throws {
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()
        await harness.spies.mockServer.retarget(udid: udid, upstream: MockSetSample.dev)

        harness.events.post(.appLaunched(simulatorID: udid))

        try await waitUntil { store.states[udid]?.upstreamHost == "api-dev.example.com" }
        #expect(store.settings(for: udid).upstream == MockSetSample.dev.absoluteString)
    }

    @Test func aLaunchThatStoppedTheServerClearsTheState() async throws {
        store.setMode(.passthrough, for: udid)
        try await applyAndWait()
        await harness.spies.mockServer.stop(udid: udid)

        harness.events.post(.buildFinished(simulatorID: udid, launchedDeviceID: nil))

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
        let restored = StoreHarness(projects: [ProjectSample.identified], store: saved)
        restored.spies.mockSets.listResult = .success([MockSetSample.vip])
        await restored.mockSets.load()

        restored.mockServer.restoreServers()

        try await waitUntil { restored.mockServer.states[udid] != nil }
        #expect(restored.spies.mockServer.calls == [.start(udid: udid, upstream: MockSetSample.qa, rules: MockSetSample.vip.rules)])
        #expect(restored.mockServer.states[udid] == MockServerState(mode: .mock, setID: MockSetSample.vip.id, upstreamHost: "api-qa.example.com", status: .running(port: 52001)))
        #expect(restored.spies.identity.calls.isEmpty)
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
