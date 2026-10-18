import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct ConfigStoreTests {
    private let harness = StoreHarness()

    private var store: ConfigStore {
        harness.config
    }

    @Test func reloadLoadsTheSelectedProjectAndPosts() async {
        harness.spies.config.loadResult = ConfigSample.resolved([ConfigSample.action("clean")])

        await store.reload()

        #expect(harness.spies.config.calls.contains(.load(projectPath: ProjectSample.path)))
        #expect(store.resolved.actions.map(\.id) == ["clean"])
        #expect(harness.postCount("configChanged") == 1)
    }

    @Test func anUnchangedReloadDoesNotPostAgain() async {
        harness.spies.config.loadResult = ConfigSample.resolved([ConfigSample.action("clean")])
        await store.reload()

        await store.reload()

        #expect(harness.postCount("configChanged") == 1)
    }

    @Test func reloadWatchesTheFolderOnce() async {
        await store.reload()
        await store.reload()

        #expect(harness.spies.config.calls.filter { $0 == .changes(projectPath: ProjectSample.path) }.count == 1)
    }

    @Test func aChangeOnDiskReloads() async throws {
        await store.reload()
        harness.spies.config.loadResult = ConfigSample.resolved([ConfigSample.action("new")])

        harness.spies.config.emitChange()

        try await waitUntil { store.resolved.actions.map(\.id) == ["new"] }
    }

    @Test func projectChangedAndScriptsRefreshReload() async throws {
        _ = store
        harness.spies.config.loadResult = ConfigSample.resolved([ConfigSample.action("a")])

        harness.events.post(.projectChanged)
        try await waitUntil { store.resolved.actions.count == 1 }

        harness.spies.config.loadResult = ConfigSample.resolved([ConfigSample.action("a"), ConfigSample.action("b")])
        harness.events.post(.refreshRequested(.scripts))
        try await waitUntil { store.resolved.actions.count == 2 }
    }

    @Test func withoutAProjectTheConfigIsEmpty() async {
        let empty = StoreHarness(projects: [])

        await empty.config.reload()

        #expect(empty.config.resolved == .empty)
        #expect(empty.spies.config.calls.isEmpty)
    }

    @Test func createExampleReturnsTheFolderAndReloads() async throws {
        let folder = try await store.createExample()

        #expect(folder == "/repo/.devhub")
        #expect(harness.spies.config.calls.contains(.createExample(projectPath: ProjectSample.path)))
        #expect(harness.spies.config.calls.contains(.load(projectPath: ProjectSample.path)))
    }

    @Test func globalLayerComesFromTheLoadedLayers() async {
        let global = ConfigLayerInfo(layer: .global, directory: "/home/.devhub", exists: true)
        harness.spies.config.loadResult = ResolvedConfig(project: .empty, actions: [], tabs: [], issues: [], layers: [global])

        await harness.config.reload()

        #expect(harness.config.globalLayer == global)
    }

    @Test func withoutLoadedLayersTheGlobalFolderIsTheHomeFolder() {
        let layer = harness.config.globalLayer

        #expect(layer.layer == .global)
        #expect(layer.directory == ProjectPath("~/.devhub").expanded)
        #expect(layer.exists == false)
    }

    @Test func effectiveUsesConfigOverDetection() async {
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(name: "Example App", git: GitConfig(baseBranch: "origin/develop")), actions: [], tabs: [], issues: [], layers: [])
        await store.reload()

        let effective = store.effective(detectedSchemes: ["App", "Widget"], detectedBaseBranch: "origin/main")

        #expect(effective.name == "Example App")
        #expect(effective.baseBranch == "origin/develop")
        #expect(effective.scheme == "App")
    }
}
