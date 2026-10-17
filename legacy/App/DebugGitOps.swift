import Foundation

@MainActor
enum DebugGitOps {
    static func run(_ script: String, in dependencies: AppDependencies) {
        Task {
            try? await Task.sleep(for: .seconds(2))
            await dependencies.git.refresh()
            for step in script.split(separator: ",").map(String.init) {
                let parts = step.split(separator: ":", maxSplits: 1).map(String.init)
                let argument = parts.count > 1 ? parts[1] : ""
                dependencies.activity.log("Debug git", detail: step, outcome: .info)
                await perform(parts[0], argument, in: dependencies)
            }
            dependencies.activity.log("Debug git", detail: "Script finished", outcome: .success)
        }
    }

    private static func perform(_ name: String, _ argument: String, in dependencies: AppDependencies) async {
        let git = dependencies.git
        let worktrees = dependencies.worktrees
        switch name {
        case "sleep": try? await Task.sleep(for: .seconds(Double(argument) ?? 1))
        case "fetch": await git.fetch()
        case "pull": await git.pull()
        case "push": await git.push()
        case "forcepush":
            git.askForcePush()
            await git.confirm()
        case "rebase":
            git.askRebase()
            await git.confirm()
        case "updatebase": await git.updateBase()
        case "stash": await git.stash()
        case "popstash": await git.popStash()
        case "switch": await git.switchTo(argument)
        case "checkout-remote": await git.checkOutRemote(argument)
        case "delete-branch": await deleteBranch(argument, git: git)
        case "stage": await stage(argument, git: git)
        case "action": runAction(argument, item: .none, in: dependencies)
        case "rowaction": runAction(argument, item: ActionItemContext(branch: "feature/ABC-1-row", worktreePath: "/row/path", rowID: "feature/ABC-1-row"), in: dependencies)
        case "diff": await diff(argument, git: git)
        case "update": await git.update(branch: argument)
        case "continueop": await git.continueOperation()
        case "abortop": await git.abortOperation()
        case "unstage": await unstage(argument, git: git)
        case "amend":
            git.amend = true
            git.commitMessage = argument
            await git.commit(thenPush: false)
        case "stageall": await git.stageAll()
        case "unstageall": await git.unstageAll()
        case "discard": await discard(argument, git: git)
        case "commit":
            git.commitMessage = argument
            await git.commit(thenPush: false)
        case "commitpush":
            git.commitMessage = argument
            await git.commit(thenPush: true)
        case "select":
            git.selectCheckout(argument == "main" ? nil : argument)
            try? await Task.sleep(for: .seconds(4))
        case "wt-create": _ = await worktrees.createWorktree(named: argument)
        case "wt-checkout": await checkout(argument, worktrees: worktrees, activity: dependencies.activity)
        case "wt-delete": await deleteWorktree(argument, worktrees: worktrees)
        case "wt-clean":
            await worktrees.refresh()
            worktrees.askClean()
            await worktrees.confirmClean()
        case "wt-prune": await worktrees.prune()
        case "wt-fetch": await worktrees.fetch()
        default: dependencies.activity.log("Debug git", detail: "Unknown step \(name)", outcome: .failure)
        }
    }

    private static func deleteBranch(_ name: String, git: GitStore) async {
        guard let branch = git.branches.local(named: name) else { return }
        await git.deleteBranch(branch)
        if git.confirmation != nil {
            await git.confirm()
        }
    }

    private static func stage(_ path: String, git: GitStore) async {
        guard let change = git.status.changes.first(where: { $0.path == path }) else { return }
        await git.stage(change)
    }

    private static func runAction(_ id: String, item: ActionItemContext, in dependencies: AppDependencies) {
        guard let action = dependencies.catalog.action(id: id) else {
            dependencies.activity.log("Debug git", detail: "No action \(id)", outcome: .failure)
            return
        }
        dependencies.runner.runWithDefaults(action, item: item)
    }

    private static func diff(_ path: String, git: GitStore) async {
        guard let change = git.status.changes.first(where: { $0.path == path }), let group = change.groups.first else { return }
        await git.toggleDiff(change, in: group)
    }

    private static func unstage(_ path: String, git: GitStore) async {
        guard let change = git.status.changes.first(where: { $0.path == path }) else { return }
        await git.unstage(change)
    }

    private static func discard(_ path: String, git: GitStore) async {
        guard let change = git.status.changes.first(where: { $0.path == path }), let group = change.groups.last else { return }
        git.askDiscard(change, in: group)
        await git.confirm()
    }

    private static func checkout(_ branch: String, worktrees: WorktreesStore, activity: ActivityLog) async {
        do {
            let path = try await worktrees.checkoutPath(forBranch: branch)
            activity.log("Debug checkout path", detail: path, outcome: .success)
        } catch {
            activity.log("Debug checkout path", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private static func deleteWorktree(_ branch: String, worktrees: WorktreesStore) async {
        await worktrees.refresh()
        guard let target = worktrees.worktrees.first(where: { $0.branch == branch }) else { return }
        worktrees.askDelete(target)
        await worktrees.delete(target, removeDerivedData: true, deleteBranch: true)
    }
}
