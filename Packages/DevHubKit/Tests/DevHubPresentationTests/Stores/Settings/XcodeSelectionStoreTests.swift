import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct XcodeSelectionStoreTests {
    private let harness = StoreHarness()
    private let beta = XcodeInstallation(appPath: "/Applications/Xcode-beta.app", version: "26.2", build: "17C5013c")
    private let release = XcodeInstallation(appPath: "/Applications/Xcode.app", version: "26.1", build: "17B55")

    private var store: XcodeSelectionStore {
        harness.xcodes
    }

    @Test func refreshListsTheAppsAndTheSystemXcode() async {
        harness.spies.xcodes.installationsResult = .success([beta, release])
        harness.spies.xcodes.selectedResult = .success(release.developerDir)

        await store.refresh()

        #expect(store.installations == [beta, release])
        #expect(store.systemDeveloperDir == release.developerDir)
    }

    @Test func aFailedListIsLogged() async {
        harness.spies.xcodes.installationsResult = .failure(TestError.scripted("mdfind failed"))

        await store.refresh()

        #expect(store.installations.isEmpty)
        #expect(harness.lastActivity?.title == "Cannot list the installed Xcode apps")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func withoutAChoiceNothingIsSet() async {
        await store.apply()

        #expect(store.effectiveDeveloperDir == nil)
        #expect(harness.spies.toolEnvironment.calls.isEmpty)
    }

    @Test func chooseSavesTheProjectAndSetsTheFolder() async throws {
        _ = store

        store.choose(beta.developerDir, for: harness.session.selectedProject)

        try await waitUntil { harness.spies.toolEnvironment.calls == [.setDeveloperDir(beta.developerDir)] }
        #expect(harness.session.selectedProject.developerDir == beta.developerDir)
        #expect(store.appliedDeveloperDir == beta.developerDir)
    }

    @Test func anEmptyChoiceGoesBackToTheDefault() async throws {
        store.choose(beta.developerDir, for: harness.session.selectedProject)
        try await waitUntil { harness.spies.toolEnvironment.calls.count == 1 }

        store.choose("", for: harness.session.selectedProject)

        try await waitUntil { harness.spies.toolEnvironment.calls.last == .setDeveloperDir(nil) }
        #expect(harness.session.selectedProject.developerDir == nil)
    }

    @Test func theProjectConfigIsUsedWithoutAChoice() async throws {
        harness.spies.config.loadResult = ResolvedConfig(
            project: ProjectConfig(xcode: XcodeConfig(developerDir: "/Applications/Xcode.app")),
            actions: [],
            tabs: [],
            issues: [],
            layers: [ConfigLayerInfo(layer: .project, directory: ConfigSample.directory, exists: true)]
        )
        _ = store
        await harness.config.reload()

        try await waitUntil { harness.spies.toolEnvironment.calls == [.setDeveloperDir(release.developerDir)] }
        #expect(store.configDeveloperDir == "/Applications/Xcode.app")
    }

    @Test func applyDoesNothingWhenTheFolderDidNotChange() async throws {
        store.choose(beta.developerDir, for: harness.session.selectedProject)
        try await waitUntil { harness.spies.toolEnvironment.calls.count == 1 }

        await store.apply()
        harness.events.post(.projectChanged)
        await harness.settle()

        #expect(harness.spies.toolEnvironment.calls.count == 1)
    }
}
