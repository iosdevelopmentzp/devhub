import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct SimulatorsStoreTests {
    private let harness = StoreHarness()
    private let failure = TestError.scripted("boom")
    private let booted = SimulatorSample.booted
    private let shutdown = SimulatorSample.shutdown

    private var store: SimulatorsStore {
        harness.simulators
    }

    private var listCalls: Int {
        harness.spies.simulators.calls.filter { $0 == .list }.count
    }

    private func load() async {
        harness.spies.simulators.listResult = .success(SimulatorSample.groups)
        await store.refresh()
    }

    // MARK: Refresh

    @Test func refreshLoadsGroupsCountsAndFavorites() async {
        let saved = InMemoryKeyValueStore()
        saved.set([booted.id], forKey: "simulators.favorites")
        let harness = StoreHarness(store: saved)
        harness.spies.simulators.listResult = .success(SimulatorSample.groups)
        harness.spies.simulators.installedAppCountsResult = [booted.id: 2]

        await harness.simulators.refresh()

        #expect(harness.simulators.all.map(\.id) == [booted.id, shutdown.id, SimulatorSample.pad.id])
        #expect(harness.simulators.simulator(id: booted.id)?.isFavorite == true)
        #expect(harness.simulators.simulator(id: shutdown.id)?.isFavorite == false)
        #expect(harness.simulators.installedAppCounts == [booted.id: 2])
        #expect(harness.simulators.error == nil)
        #expect(harness.spies.simulators.calls == [.list, .installedAppCounts(udids: [booted.id, shutdown.id, SimulatorSample.pad.id])])
        #expect(harness.postedLabels == ["simulatorsChanged"])
    }

    @Test func everySuccessfulRefreshPostsSimulatorsChanged() async {
        await load()
        await store.refresh()

        #expect(harness.postCount("simulatorsChanged") == 2)
    }

    @Test func aFailedRefreshSetsTheErrorAndLogs() async {
        harness.spies.simulators.listResult = .failure(failure)

        await store.refresh()

        #expect(store.error == failure.localizedDescription)
        #expect(harness.lastActivity?.title == "Simulator list failed")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.postedLabels.isEmpty)
    }

    @Test func buildFinishedAndAppLaunchedRefresh() async throws {
        _ = store
        harness.events.post(.buildFinished(simulatorID: booted.id, launch: nil))
        try await waitUntil { listCalls == 1 }

        harness.events.post(.appLaunched(simulatorID: booted.id, launch: nil))
        try await waitUntil { listCalls == 2 }
    }

    // MARK: Lookups

    @Test func lookupsReadTheGroups() async {
        await load()
        store.installedAppCounts = [booted.id: 3, shutdown.id: 0]

        #expect(store.withApps == [booted])
        #expect(store.simulator(id: shutdown.id) == shutdown)
        #expect(store.simulator(id: "unknown") == nil)
        #expect(store.runtime(for: SimulatorSample.pad.id) == "iOS 18.6")
        #expect(store.runtime(for: "unknown") == nil)
    }

    // MARK: Favorites

    @Test func toggleFavoriteAddsAtTheEndAndPersistsTheOrder() async {
        await load()

        store.toggleFavorite(id: shutdown.id)
        store.toggleFavorite(id: booted.id)

        #expect(store.favoriteOrder == [shutdown.id, booted.id])
        #expect(harness.store.strings(forKey: "simulators.favorites") == [shutdown.id, booted.id])
        #expect(store.simulator(id: shutdown.id)?.isFavorite == true)

        store.toggleFavorite(id: shutdown.id)

        #expect(harness.store.strings(forKey: "simulators.favorites") == [booted.id])
        #expect(store.simulator(id: shutdown.id)?.isFavorite == false)
    }

    @Test func moveFavoritePutsItAtTheTargetAndPersists() async {
        await load()
        store.toggleFavorite(id: shutdown.id)
        store.toggleFavorite(id: booted.id)

        store.moveFavorite(id: booted.id, onto: shutdown.id)

        #expect(store.favoriteOrder == [booted.id, shutdown.id])
        #expect(harness.store.strings(forKey: "simulators.favorites") == [booted.id, shutdown.id])
    }

    @Test func moveFavoriteIgnoresAnIDThatIsNotAFavorite() async {
        await load()
        store.toggleFavorite(id: shutdown.id)

        store.moveFavorite(id: "unknown", onto: shutdown.id)

        #expect(store.favoriteOrder == [shutdown.id])
    }

    @Test func theSavedOrderIsRestored() {
        let saved = InMemoryKeyValueStore()
        saved.set(["b", "a"], forKey: "simulators.favorites")

        #expect(StoreHarness(store: saved).simulators.favoriteOrder == ["b", "a"])
    }

    // MARK: Power

    @Test func togglePowerShutsDownABootedSimulator() async throws {
        await load()

        store.togglePower(id: booted.id)

        #expect(store.simulator(id: booted.id)?.state == .shuttingDown)
        try await waitUntil { listCalls == 2 }
        #expect(harness.spies.simulators.calls.contains(.shutdown(udid: booted.id)))
        #expect(harness.lastActivity?.title == "Shut down iPhone 17")
        #expect(harness.lastActivity?.detail == "iOS 26.0")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func togglePowerBootsAShutDownSimulator() async throws {
        await load()

        store.togglePower(id: shutdown.id)

        #expect(store.simulator(id: shutdown.id)?.state == .booting)
        try await waitUntil { listCalls == 2 }
        #expect(harness.spies.simulators.calls.contains(.boot(udid: shutdown.id)))
        #expect(harness.lastActivity?.title == "Booted iPhone 16e")
    }

    @Test func togglePowerIgnoresATransitioningSimulator() async {
        await load()
        store.togglePower(id: booted.id)

        store.togglePower(id: booted.id)

        #expect(store.simulator(id: booted.id)?.state == .shuttingDown)
    }

    @Test func aFailedPowerChangeLogsAFailureWithoutCommandFailed() async throws {
        await load()
        harness.spies.simulators.bootError = failure

        store.togglePower(id: shutdown.id)

        try await waitUntil { listCalls == 2 }
        #expect(harness.lastActivity?.title == "Booted failed: iPhone 16e")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.postCount("commandFailed") == 0)
    }

    @Test func eraseErasesTheSimulator() async throws {
        await load()

        store.erase(id: booted.id)

        #expect(store.simulator(id: booted.id)?.state == .shuttingDown)
        try await waitUntil { listCalls == 2 }
        #expect(harness.spies.simulators.calls.contains(.erase(udid: booted.id)))
        #expect(harness.lastActivity?.title == "Erased iPhone 17")
    }

    @Test func openInSimulatorAppOpensIt() async throws {
        await load()

        store.openInSimulatorApp(id: booted.id)

        try await waitUntil { listCalls == 2 }
        #expect(harness.spies.simulators.calls.contains(.openInSimulatorApp(udid: booted.id)))
        #expect(harness.lastActivity?.title == "Opened in Simulator.app iPhone 17")
    }

    @Test func actionsOnAnUnknownSimulatorDoNothing() {
        store.togglePower(id: "unknown")
        store.erase(id: "unknown")
        store.openInSimulatorApp(id: "unknown")
        store.uninstallUserApps(id: "unknown")

        #expect(harness.spies.simulators.calls.isEmpty)
        #expect(store.uninstallingIDs.isEmpty)
    }

    // MARK: Apps

    @Test func uninstallUserAppsLogsTheRemovedApps() async throws {
        await load()
        harness.spies.simulators.uninstallUserAppsResult = .success(["com.example.a", "com.example.b"])

        store.uninstallUserApps(id: booted.id)

        #expect(store.isUninstalling(booted.id))
        try await waitUntil { listCalls == 2 }
        #expect(store.isUninstalling(booted.id) == false)
        #expect(harness.spies.simulators.calls.contains(.uninstallUserApps(udid: booted.id, wasBooted: true)))
        #expect(harness.lastActivity?.title == "Removed apps from iPhone 17")
        #expect(harness.lastActivity?.detail == "com.example.a, com.example.b")
    }

    @Test func aFailedUninstallUserAppsLogsAFailure() async throws {
        await load()
        harness.spies.simulators.uninstallUserAppsResult = .failure(failure)

        store.uninstallUserApps(id: shutdown.id)

        try await waitUntil { listCalls == 2 }
        #expect(harness.lastActivity?.title == "Removing apps failed: iPhone 16e")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func uninstallRemovesOneApp() async throws {
        await load()

        store.uninstall(bundleID: "com.example.a", from: shutdown.id)

        #expect(store.isUninstalling(shutdown.id))
        try await waitUntil { listCalls == 2 }
        #expect(harness.spies.simulators.calls.contains(.uninstall(udid: shutdown.id, bundleID: "com.example.a", wasBooted: false)))
        #expect(harness.lastActivity?.title == "Uninstalled com.example.a")
        #expect(harness.lastActivity?.detail == "iPhone 16e")
    }

    @Test func aFailedUninstallLogsAFailure() async throws {
        await load()
        harness.spies.simulators.uninstallError = failure

        store.uninstall(bundleID: "com.example.a", from: shutdown.id)

        try await waitUntil { listCalls == 2 }
        #expect(harness.lastActivity?.title == "Uninstall failed: iPhone 16e")
    }

    @Test func removeAppsFromAllWalksEverySimulatorWithApps() async throws {
        await load()
        store.installedAppCounts = [booted.id: 2, shutdown.id: 1]
        harness.spies.simulators.uninstallUserAppsResult = .success(["com.example.a"])

        store.removeAppsFromAll()

        #expect(store.bulkUninstall == BulkProgress(done: 0, total: 2, current: booted.name))
        try await waitUntil { listCalls == 2 }
        #expect(store.bulkUninstall == nil)
        #expect(store.uninstallingIDs.isEmpty)
        #expect(harness.spies.simulators.calls.filter { if case .uninstallUserApps = $0 { true } else { false } } == [
            .uninstallUserApps(udid: booted.id, wasBooted: true),
            .uninstallUserApps(udid: shutdown.id, wasBooted: false),
        ])
        #expect(harness.lastActivity?.title == "Removed apps from all simulators")
        #expect(harness.lastActivity?.detail == "2 apps")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func removeAppsFromAllWithoutAppsDoesNothing() async {
        await load()

        store.removeAppsFromAll()

        #expect(store.bulkUninstall == nil)
    }

    @Test func cancelBulkUninstallStopsBeforeTheNextSimulator() async throws {
        await load()
        store.installedAppCounts = [booted.id: 2, shutdown.id: 1]

        store.removeAppsFromAll()
        store.cancelBulkUninstall()

        try await waitUntil { store.bulkUninstall == nil }
        #expect(harness.lastActivity?.title == "Stopped removing apps")
        #expect(harness.lastActivity?.detail == "0 apps")
        #expect(harness.spies.simulators.calls.contains { if case .uninstallUserApps = $0 { true } else { false } } == false)
    }
}
