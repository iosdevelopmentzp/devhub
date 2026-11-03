import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct WorktreesStoreTests {
    private let harness = StoreHarness()
    private let failure = TestError.scripted("boom")

    private var store: WorktreesStore {
        harness.worktrees
    }

    private var listCalls: Int {
        harness.spies.worktrees.calls.filter { $0 == .list(projectPath: harness.session.selectedProject.path) }.count
    }

    private func useConfig(_ git: GitConfig) async {
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(git: git), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
    }

    private func useBootstrap() async {
        await useConfig(GitConfig(worktrees: WorktreesConfig(bootstrap: "scripts/bootstrap.sh", bootstrapMarker: "Pods")))
    }

    // MARK: Refresh

    @Test func refreshUsesTheGitSettingsOfTheConfig() async {
        await useConfig(GitConfig(remote: "upstream", baseBranch: "upstream/develop", worktrees: WorktreesConfig(folder: ".worktrees")))
        harness.spies.worktrees.baseBranchResult = "upstream/main"

        await store.refresh()

        #expect(store.baseBranch == "upstream/develop")
        #expect(harness.spies.worktrees.remotes == ["upstream"])
        #expect(harness.spies.worktrees.settings.first?.worktrees.folder == ".worktrees")
    }

    @Test func aChangedGitConfigRefreshes() async throws {
        _ = store
        await useConfig(GitConfig(remote: "upstream"))

        try await waitUntil { harness.spies.worktrees.remotes.contains("upstream") }
    }

    @Test func anActionOnlyConfigChangeDoesNotRefresh() async {
        await store.refresh()
        let before = listCalls

        harness.events.post(.configChanged)

        #expect(listCalls == before)
    }

    @Test func bootstrapWithoutAScriptDoesNothing() async {
        store.worktrees = [WorktreeSample.needsBootstrap]

        store.bootstrap(id: WorktreeSample.needsBootstrap.id)

        #expect(store.bootstrappingIDs.isEmpty)
        #expect(harness.spies.worktrees.calls.isEmpty)
    }

    @Test func aNewWorktreeRunsTheBootstrapOnceWithoutAMarker() async throws {
        await useConfig(GitConfig(worktrees: WorktreesConfig(bootstrap: "scripts/bootstrap.sh")))
        harness.spies.worktrees.createResult = .success(NewWorktree(path: WorktreeSample.feature.path, branch: "feature/login"))
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.feature])

        _ = await store.createAndBootstrap(branch: "feature/login")

        try await waitUntil { harness.spies.worktrees.scripts == ["scripts/bootstrap.sh"] }
        #expect(harness.operations.latest(at: .worktrees)?.title == "Create worktree for feature/login")
        try await waitUntil { harness.operations.latest(at: .worktree(WorktreeSample.feature.id))?.status == .succeeded }
    }

    @Test func refreshLoadsTheListAndTheBaseBranch() async {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.feature])
        harness.spies.worktrees.baseBranchResult = "origin/main"

        await store.refresh()

        #expect(store.worktrees == [WorktreeSample.main, WorktreeSample.feature])
        #expect(store.baseBranch == "origin/main")
        #expect(store.error == nil)
        #expect(store.isLoading == false)
        #expect(Set(harness.spies.worktrees.calls) == [.list(projectPath: ProjectSample.path), .baseBranch(projectPath: ProjectSample.path), .location(projectPath: ProjectSample.path)])
        #expect(harness.postedLabels == ["worktreesChanged"])
    }

    @Test func twoRefreshesWithTheSameDataPostOnce() async {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main])

        await store.refresh()
        await store.refresh()

        #expect(harness.postCount("worktreesChanged") == 1)
    }

    @Test func aChangedBaseBranchPostsAgain() async {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main])
        await store.refresh()

        harness.spies.worktrees.baseBranchResult = "origin/develop"
        await store.refresh()

        #expect(harness.postCount("worktreesChanged") == 2)
    }

    @Test func refreshWithAnEmptyListAndTheDefaultBaseDoesNotPost() async {
        await store.refresh()

        #expect(harness.postedLabels.isEmpty)
    }

    @Test func aFailingListClearsTheListAndPostsWhenItWasNotEmpty() async {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main])
        await store.refresh()

        harness.spies.worktrees.listResult = .failure(failure)
        await store.refresh()

        #expect(store.worktrees.isEmpty)
        #expect(store.error == failure.localizedDescription)
        #expect(harness.postCount("worktreesChanged") == 2)
    }

    @Test func aFailingListOnAnEmptyListDoesNotPost() async {
        harness.spies.worktrees.listResult = .failure(failure)

        await store.refresh()

        #expect(store.error == failure.localizedDescription)
        #expect(harness.postedLabels.isEmpty)
    }

    @Test func derivedDataSizesAreLoadedForAvailableCheckouts() async {
        let folder = URL(fileURLWithPath: "/tmp/DevHubTests/DerivedData")
        harness.spies.derivedData.folderResult = folder
        harness.spies.derivedData.sizeResult = 100
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.feature, WorktreeSample.missing])

        await store.refresh()

        #expect(store.derivedDataSizes == [WorktreeSample.main.id: 100, WorktreeSample.feature.id: 100])
        #expect(store.linkedDerivedDataSize == 100)
        #expect(store.derivedDataSize(of: [WorktreeSample.main, WorktreeSample.feature]) == 200)
        #expect(harness.spies.derivedData.calls.contains(.folder(checkout: WorktreeSample.missing.path)) == false)
    }

    // MARK: Events

    @Test func projectChangedClearsTheListAndRefreshesTheNewProject() async throws {
        let harness = StoreHarness(projects: [ProjectSample.app, ProjectSample.other])
        let store = harness.worktrees
        store.worktrees = [WorktreeSample.main]

        harness.session.selectedProjectID = ProjectSample.other.id

        #expect(store.worktrees.isEmpty)
        try await waitUntil { harness.spies.worktrees.calls.contains(.list(projectPath: ProjectSample.other.path)) }
    }

    @Test func branchesChangedRefreshes() async throws {
        _ = store
        harness.events.post(.branchesChanged)

        try await waitUntil { listCalls == 1 }
    }

    @Test func worktreeCheckoutPreparedRefreshes() async throws {
        _ = store
        harness.events.post(.worktreeCheckoutPrepared)

        try await waitUntil { listCalls == 1 }
    }

    @Test func worktreeBootstrappingInsertsAndRemovesTheID() {
        _ = store
        harness.events.post(.worktreeBootstrapping(path: WorktreeSample.feature.path, isRunning: true))
        #expect(store.bootstrappingIDs == [WorktreeSample.feature.id])

        harness.events.post(.worktreeBootstrapping(path: WorktreeSample.feature.path, isRunning: false))
        #expect(store.bootstrappingIDs.isEmpty)
    }

    // MARK: Lookups

    @Test func mainCheckoutPathFallsBackToTheProjectPath() {
        #expect(store.mainWorktree == nil)
        #expect(store.mainCheckoutPath == ProjectSample.path)
    }

    @Test func lookupsReadTheList() {
        store.worktrees = [WorktreeSample.main, WorktreeSample.feature, WorktreeSample.merged, WorktreeSample.missing]

        #expect(store.mainWorktree == WorktreeSample.main)
        #expect(store.mainCheckoutPath == WorktreeSample.main.path)
        #expect(store.availableCheckouts == [WorktreeSample.main, WorktreeSample.feature, WorktreeSample.merged])
        #expect(store.worktree(atPath: WorktreeSample.feature.path) == WorktreeSample.feature)
        #expect(store.checkoutPath(forBranch: "origin/feature/login") == WorktreeSample.feature.path)
        #expect(store.checkoutPath(forBranch: "feature/gone") == nil)
        #expect(store.finishedWorktrees(excluding: nil) == [WorktreeSample.merged])
        #expect(store.finishedWorktrees(excluding: WorktreeSample.merged.path).isEmpty)
        #expect(store.missingCount == 1)
    }

    // MARK: Delete

    @Test func deleteRemovesTheWorktreeLogsTheSummaryAndRefreshes() async throws {
        store.worktrees = [WorktreeSample.main, WorktreeSample.feature]

        store.delete(id: WorktreeSample.feature.id, deleteDerivedData: false, deleteBranch: true)

        #expect(store.busyIDs == [WorktreeSample.feature.id])
        try await waitUntil { listCalls == 1 }
        #expect(store.busyIDs.isEmpty)
        #expect(harness.spies.worktrees.calls.prefix(2) == [
            .remove(WorktreeSample.feature, projectPath: ProjectSample.path),
            .deleteBranch("feature/login", projectPath: ProjectSample.path),
        ])
        #expect(harness.lastActivity?.title == "Removed worktree")
        #expect(harness.lastActivity?.outcome == .info)
        #expect(harness.operations.latest(at: .worktree(WorktreeSample.feature.id))?.status == .succeeded)
    }

    @Test func aFailedDeleteLogsAFailure() async throws {
        store.worktrees = [WorktreeSample.main, WorktreeSample.feature]
        harness.spies.worktrees.removeError = failure

        store.delete(id: WorktreeSample.feature.id, deleteDerivedData: false, deleteBranch: true)

        try await waitUntil { listCalls == 1 }
        #expect(harness.lastActivity?.title == "Could not remove worktree")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.operations.latest(at: .worktree(WorktreeSample.feature.id))?.failureMessage?.isEmpty == false)
    }

    @Test func deleteIgnoresTheMainWorktree() {
        store.worktrees = [WorktreeSample.main]

        store.delete(id: WorktreeSample.main.id, deleteDerivedData: true, deleteBranch: true)

        #expect(store.busyIDs.isEmpty)
    }

    // MARK: Clean and prune

    @Test func cleanRemovesTheTargetsAndLogsTheReport() async throws {
        store.worktrees = [WorktreeSample.main, WorktreeSample.merged]

        store.clean([WorktreeSample.merged])

        #expect(store.busyIDs == [WorktreeSample.merged.id])
        try await waitUntil { listCalls == 1 }
        #expect(store.busyIDs.isEmpty)
        #expect(harness.spies.worktrees.calls.contains(.remove(WorktreeSample.merged, projectPath: ProjectSample.path)))
        #expect(harness.lastActivity?.title == "Cleaned finished worktrees")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func aFailedCleanLogsAFailure() async throws {
        harness.spies.worktrees.removeError = failure

        store.clean([WorktreeSample.merged])

        try await waitUntil { listCalls == 1 }
        #expect(harness.lastActivity?.title == "Cleaned finished worktrees")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func cleanWithoutTargetsDoesNothing() {
        store.clean([])

        #expect(store.busyIDs.isEmpty)
        #expect(harness.spies.worktrees.calls.isEmpty)
    }

    @Test func pruneLogsTheStaleWorktrees() async throws {
        store.worktrees = [WorktreeSample.main, WorktreeSample.missing]

        store.prune()

        try await waitUntil { listCalls == 1 }
        #expect(harness.spies.worktrees.calls.first == .prune(projectPath: ProjectSample.path))
        #expect(harness.lastActivity?.title == "Pruned 1 worktree(s)")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func aFailedPruneLogsAFailure() async throws {
        harness.spies.worktrees.pruneError = failure

        store.prune()

        try await waitUntil { listCalls == 1 }
        #expect(harness.lastActivity?.title == "Prune failed")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    // MARK: Location

    @Test func refreshReadsTheLocation() async {
        harness.spies.worktrees.locationResult = .insideProject

        await store.refresh()

        #expect(store.location == .insideProject)
    }

    @Test func keepInsideProjectChangesTheLocationAndLogs() async throws {
        harness.spies.worktrees.locationAfterKeep = .insideProject

        store.keepInsideProject()

        #expect(store.isMovingInside)
        try await waitUntil { store.isMovingInside == false }
        #expect(harness.spies.worktrees.calls == [.keepInsideProject(projectPath: ProjectSample.path), .location(projectPath: ProjectSample.path)])
        #expect(store.location == .insideProject)
        #expect(harness.lastActivity?.title == "New worktrees go inside the project")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func aFailedKeepInsideProjectLogsAFailureAndKeepsTheLocation() async throws {
        harness.spies.worktrees.keepInsideProjectError = failure

        store.keepInsideProject()

        try await waitUntil { store.isMovingInside == false }
        #expect(store.location == .nextToProject)
        #expect(harness.lastActivity?.title == "Could not keep worktrees inside the project")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    // MARK: Create and bootstrap

    @Test func createLogsAndReturnsTheNewWorktree() async {
        harness.spies.worktrees.createResult = .success(NewWorktree(path: WorktreeSample.created.path, branch: "feature/created"))
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.created])

        let created = await store.create(branch: " origin/feature/created ")

        #expect(created == WorktreeSample.created)
        #expect(harness.spies.worktrees.calls.first == .create(branch: "feature/created", base: "origin/main", projectPath: ProjectSample.path))
        #expect(harness.lastActivity?.title == "Created worktree")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func createWithAnEmptyNameReturnsNil() async {
        let created = await store.create(branch: "  ")

        #expect(created == nil)
        #expect(harness.spies.worktrees.calls.isEmpty)
    }

    @Test func aFailedCreateLogsAFailure() async {
        harness.spies.worktrees.createResult = .failure(failure)

        let created = await store.create(branch: "feature/created")

        #expect(created == nil)
        #expect(harness.lastActivity?.title == "Could not create worktree")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func createAndBootstrapRunsTheScriptForANewWorktree() async throws {
        await useBootstrap()
        harness.spies.worktrees.createResult = .success(NewWorktree(path: WorktreeSample.needsBootstrap.path, branch: "feature/new"))
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.needsBootstrap])

        let created = await store.createAndBootstrap(branch: "feature/new")

        #expect(created)
        try await waitUntil { harness.activityTitles.contains("Bootstrapped feature/new") }
        #expect(harness.spies.worktrees.calls.contains(.bootstrap(worktreePath: WorktreeSample.needsBootstrap.path)))
    }

    @Test func createAndBootstrapReturnsFalseWhenNothingWasCreated() async {
        let created = await store.createAndBootstrap(branch: "")

        #expect(created == false)
    }

    @Test func bootstrapLogsSuccess() async throws {
        await useBootstrap()
        store.worktrees = [WorktreeSample.needsBootstrap]

        store.bootstrap(id: WorktreeSample.needsBootstrap.id)

        try await waitUntil { listCalls == 1 }
        #expect(store.bootstrappingIDs.isEmpty)
        #expect(harness.activityTitles.contains("Bootstrapped feature/new"))
    }

    @Test func bootstrapLogsFailure() async throws {
        await useBootstrap()
        store.worktrees = [WorktreeSample.needsBootstrap]
        harness.spies.worktrees.bootstrapError = failure

        store.bootstrap(id: WorktreeSample.needsBootstrap.id)

        try await waitUntil { listCalls == 1 }
        #expect(store.bootstrappingIDs.isEmpty)
        #expect(harness.activityTitles.contains("Bootstrap failed: feature/new"))
        #expect(harness.activity.events.first { $0.title == "Bootstrap failed: feature/new" }?.outcome == .failure)
    }

    // MARK: Fetch

    @Test func fetchAndRefreshFetchesThenRefreshes() async throws {
        store.fetchAndRefresh()

        #expect(store.isFetching)
        try await waitUntil { listCalls == 1 }
        #expect(store.isFetching == false)
        #expect(harness.spies.worktrees.calls.first == .fetch(projectPath: ProjectSample.path))
        #expect(harness.activity.events.isEmpty)
    }

    @Test func fetchAndRefreshLogsAFailedFetch() async throws {
        harness.spies.worktrees.fetchError = failure

        store.fetchAndRefresh()

        try await waitUntil { listCalls == 1 }
        #expect(harness.lastActivity?.title == "git fetch failed")
        #expect(harness.lastActivity?.outcome == .failure)
    }
}
