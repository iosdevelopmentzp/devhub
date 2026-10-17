import Foundation

package struct PrepareBuildCheckoutUseCase: Sendable {
    package struct Prepared: Sendable {
        package let path: String
        package let worktreeName: String?
        package let createdWorktree: Bool
        package let bootstrapped: Bool
    }

    package let worktrees: any WorktreeRepository
    package let createWorktree: CreateWorktreeUseCase

    package func execute(
        source: BuildSourceChoice,
        worktrees known: [Worktree],
        mainCheckoutPath: String,
        projectName: String,
        projectPath: String,
        baseBranch: String,
        onStep: @escaping @Sendable (String) -> Void,
        onBootstrap: @escaping @Sendable (_ path: String, _ isRunning: Bool) -> Void
    ) async throws -> Prepared {
        var current = known
        var createdWorktree = false
        if case .branch(let name) = source, BuildSourceResolver.checkoutPath(forBranch: name, in: current) == nil {
            onStep("Creating a worktree for \(name)")
            current = try await create(branch: name, baseBranch: baseBranch, projectPath: projectPath)
            createdWorktree = true
        }
        let path = BuildSourceResolver.resolve(
            source: source,
            worktrees: current,
            mainCheckoutPath: mainCheckoutPath,
            projectName: projectName
        ).path
        let worktree = current.first { $0.path == path }
        guard let worktree, worktree.needsBootstrap else {
            return Prepared(path: path, worktreeName: worktree?.displayName, createdWorktree: createdWorktree, bootstrapped: false)
        }
        onStep("Running init.sh in \(worktree.displayName)")
        onBootstrap(worktree.path, true)
        defer { onBootstrap(worktree.path, false) }
        do {
            try await worktrees.bootstrap(worktreePath: worktree.path) { _ in }
        } catch {
            throw BuildSourceError.bootstrapFailed(
                worktreeName: worktree.displayName,
                path: worktree.path,
                createdWorktree: createdWorktree,
                message: error.localizedDescription
            )
        }
        return Prepared(path: path, worktreeName: worktree.displayName, createdWorktree: createdWorktree, bootstrapped: true)
    }

    private func create(branch name: String, baseBranch: String, projectPath: String) async throws -> [Worktree] {
        let created: NewWorktree?
        do {
            created = try await createWorktree.execute(branch: name, base: baseBranch, projectPath: projectPath)
        } catch {
            throw BuildSourceError.creationFailed(branch: name, message: error.localizedDescription)
        }
        guard let created else { throw BuildSourceError.worktreeNotCreated(name) }
        let listed = (try? await worktrees.list(projectPath: projectPath)) ?? []
        guard listed.contains(where: { $0.path == created.path }) else { throw BuildSourceError.worktreeNotCreated(name) }
        return listed
    }
}
