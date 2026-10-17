import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct PrepareBuildCheckoutUseCaseTests {
    private let feature = WorktreeFixture.linked(branch: "feature")
    private let steps = CallbackRecorder<String>()
    private let bootstraps = CallbackRecorder<BootstrapEvent>()

    @Test func mainSourceUsesTheMainCheckout() async throws {
        let (ports, spies) = Ports.spies()

        let prepared = try await prepare(ports, source: .main, known: [WorktreeFixture.main, feature])

        #expect(prepared.path == WorktreeFixture.mainPath)
        #expect(prepared.worktreeName == "dev")
        #expect(prepared.createdWorktree == false)
        #expect(prepared.bootstrapped == false)
        #expect(spies.worktrees.calls.isEmpty)
        #expect(steps.values.isEmpty)
    }

    @Test func worktreeSourceUsesItsPath() async throws {
        let (ports, spies) = Ports.spies()

        let prepared = try await prepare(ports, source: .worktree(feature.path), known: [WorktreeFixture.main, feature])

        #expect(prepared.path == feature.path)
        #expect(prepared.worktreeName == "feature")
        #expect(spies.worktrees.calls.isEmpty)
    }

    @Test func branchWithAWorktreeUsesThatWorktree() async throws {
        let (ports, spies) = Ports.spies()

        let prepared = try await prepare(ports, source: .branch("origin/feature"), known: [WorktreeFixture.main, feature])

        #expect(prepared.path == feature.path)
        #expect(prepared.createdWorktree == false)
        #expect(spies.worktrees.calls.isEmpty)
    }

    @Test func branchWithoutAWorktreeCreatesOne() async throws {
        let (ports, spies) = Ports.spies()
        scriptCreation(spies, listed: [WorktreeFixture.main, feature])

        let prepared = try await prepare(ports, source: .branch("origin/feature"), known: [WorktreeFixture.main])

        #expect(spies.worktrees.calls == [
            .create(branch: "feature", base: "origin/dev", projectPath: "/repo"),
            .list(projectPath: "/repo"),
        ])
        #expect(steps.values == ["Creating a worktree for origin/feature"])
        #expect(prepared.path == feature.path)
        #expect(prepared.worktreeName == "feature")
        #expect(prepared.createdWorktree)
        #expect(prepared.bootstrapped == false)
        #expect(bootstraps.values.isEmpty)
    }

    @Test func newWorktreeThatNeedsBootstrapIsBootstrapped() async throws {
        let (ports, spies) = Ports.spies()
        var fresh = feature
        fresh.needsBootstrap = true
        scriptCreation(spies, listed: [WorktreeFixture.main, fresh])

        let prepared = try await prepare(ports, source: .branch("feature"), known: [WorktreeFixture.main])

        #expect(spies.worktrees.calls == [
            .create(branch: "feature", base: "origin/dev", projectPath: "/repo"),
            .list(projectPath: "/repo"),
            .bootstrap(worktreePath: fresh.path),
        ])
        #expect(steps.values == ["Creating a worktree for feature", "Running init.sh in feature"])
        #expect(bootstraps.values == [BootstrapEvent(path: fresh.path, isRunning: true), BootstrapEvent(path: fresh.path, isRunning: false)])
        #expect(prepared.createdWorktree)
        #expect(prepared.bootstrapped)
    }

    @Test func existingWorktreeThatNeedsBootstrapIsBootstrappedWithoutCreation() async throws {
        let (ports, spies) = Ports.spies()
        var fresh = feature
        fresh.needsBootstrap = true

        let prepared = try await prepare(ports, source: .worktree(fresh.path), known: [WorktreeFixture.main, fresh])

        #expect(spies.worktrees.calls == [.bootstrap(worktreePath: fresh.path)])
        #expect(prepared.createdWorktree == false)
        #expect(prepared.bootstrapped)
    }

    @Test func failedCreationIsCreationFailed() async {
        let (ports, spies) = Ports.spies()
        spies.worktrees.createResult = .failure(TestError.scripted("exit 128"))

        let error = await #expect(throws: BuildSourceError.self) {
            try await prepare(ports, source: .branch("feature"), known: [WorktreeFixture.main])
        }

        guard case .creationFailed(let branch, _) = error else {
            Issue.record("Expected .creationFailed, got \(String(describing: error))")
            return
        }
        #expect(branch == "feature")
    }

    @Test func branchWithAnEmptyLocalNameIsNotCreated() async {
        let (ports, spies) = Ports.spies()

        let error = await #expect(throws: BuildSourceError.self) {
            try await prepare(ports, source: .branch("origin/"), known: [WorktreeFixture.main])
        }

        guard case .worktreeNotCreated(let branch) = error else {
            Issue.record("Expected .worktreeNotCreated, got \(String(describing: error))")
            return
        }
        #expect(branch == "origin/")
        #expect(spies.worktrees.calls.isEmpty)
    }

    @Test func createdWorktreeMissingFromTheListIsNotCreated() async {
        let (ports, spies) = Ports.spies()
        scriptCreation(spies, listed: [WorktreeFixture.main])

        let error = await #expect(throws: BuildSourceError.self) {
            try await prepare(ports, source: .branch("feature"), known: [WorktreeFixture.main])
        }

        guard case .worktreeNotCreated(let branch) = error else {
            Issue.record("Expected .worktreeNotCreated, got \(String(describing: error))")
            return
        }
        #expect(branch == "feature")
    }

    @Test func failedListAfterCreationIsNotCreated() async {
        let (ports, spies) = Ports.spies()
        spies.worktrees.createResult = .success(NewWorktree(path: feature.path, branch: "feature"))
        spies.worktrees.listResult = .failure(TestError.scripted("git failed"))

        let error = await #expect(throws: BuildSourceError.self) {
            try await prepare(ports, source: .branch("feature"), known: [WorktreeFixture.main])
        }

        guard case .worktreeNotCreated = error else {
            Issue.record("Expected .worktreeNotCreated, got \(String(describing: error))")
            return
        }
    }

    @Test func failedBootstrapIsBootstrapFailedAndStillEnds() async {
        let (ports, spies) = Ports.spies()
        var fresh = feature
        fresh.needsBootstrap = true
        scriptCreation(spies, listed: [WorktreeFixture.main, fresh])
        spies.worktrees.bootstrapError = TestError.scripted("init.sh failed")

        let error = await #expect(throws: BuildSourceError.self) {
            try await prepare(ports, source: .branch("feature"), known: [WorktreeFixture.main])
        }

        guard case .bootstrapFailed(let name, let path, let created, _) = error else {
            Issue.record("Expected .bootstrapFailed, got \(String(describing: error))")
            return
        }
        #expect(name == "feature")
        #expect(path == fresh.path)
        #expect(created)
        #expect(bootstraps.values == [BootstrapEvent(path: fresh.path, isRunning: true), BootstrapEvent(path: fresh.path, isRunning: false)])
    }

    private func scriptCreation(_ spies: PortSpies, listed: [Worktree]) {
        spies.worktrees.createResult = .success(NewWorktree(path: feature.path, branch: "feature"))
        spies.worktrees.listResult = .success(listed)
    }

    private func prepare(_ ports: Ports, source: BuildSourceChoice, known: [Worktree]) async throws -> PrepareBuildCheckoutUseCase.Prepared {
        let steps = steps
        let bootstraps = bootstraps
        return try await PrepareBuildCheckoutUseCase(
            worktrees: ports.worktrees,
            createWorktree: CreateWorktreeUseCase(worktrees: ports.worktrees)
        ).execute(
            source: source,
            worktrees: known,
            mainCheckoutPath: WorktreeFixture.mainPath,
            projectName: "App",
            projectPath: "/repo",
            baseBranch: "origin/dev",
            onStep: { steps.append($0) },
            onBootstrap: { bootstraps.append(BootstrapEvent(path: $0, isRunning: $1)) }
        )
    }
}

private struct BootstrapEvent: Equatable, Sendable {
    let path: String
    let isRunning: Bool
}
