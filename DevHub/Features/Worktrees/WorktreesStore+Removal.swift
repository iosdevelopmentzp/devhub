import Foundation

extension WorktreesStore {
    func fetch() async {
        guard let main = mainPath, workingTitle == nil else { return }
        setWorking("Fetching")
        defer { setWorking(nil) }
        _ = await executor.perform(.fetch(prune: true), at: main)
        await refresh()
        announceChange()
    }

    func prune() async {
        guard let main = mainPath, workingTitle == nil else { return }
        setWorking("Pruning")
        defer { setWorking(nil) }
        _ = await executor.perform(.worktreePrune, at: main)
        await refresh()
        announceChange()
    }

    func askDelete(_ worktree: WorktreeInfo) {
        setPendingClean(nil)
        setPendingDelete(worktree.path)
    }

    func cancelDelete() {
        setPendingDelete(nil)
    }

    func delete(_ worktree: WorktreeInfo, removeDerivedData: Bool, deleteBranch: Bool) async {
        setPendingDelete(nil)
        guard await remove(worktree, removeDerivedData: removeDerivedData, deleteBranch: deleteBranch) else { return }
        await refresh()
        announceChange()
    }

    func askClean() {
        setPendingDelete(nil)
        setPendingClean(cleanable)
    }

    func cancelClean() {
        setPendingClean(nil)
    }

    var cleanable: [WorktreeInfo] {
        worktrees.filter { $0.isRemovable && $0.path != buildSourcePath }
    }

    func confirmClean() async {
        let list = pendingClean ?? []
        setPendingClean(nil)
        guard list.isEmpty == false else { return }
        setWorking("Cleaning finished worktrees")
        defer { setWorking(nil) }
        var removed = 0
        for worktree in list where await remove(worktree, removeDerivedData: true, deleteBranch: true) {
            removed += 1
        }
        toaster.show(removed == 1 ? "Removed 1 worktree" : "Removed \(removed) worktrees", tint: removed == list.count ? .green : .orange)
        await refresh()
        announceChange()
    }

    private func remove(_ worktree: WorktreeInfo, removeDerivedData: Bool, deleteBranch: Bool) async -> Bool {
        guard let main = mainPath, worktree.isMain == false else { return false }
        markBusy(worktree.path, true)
        defer { markBusy(worktree.path, false) }
        let force = worktree.isDirty || worktree.isLocked
        guard await executor.perform(.worktreeRemove(worktree.path, force: force), at: main, title: "Delete worktree \(worktree.title)") != nil else {
            return false
        }
        if removeDerivedData {
            await deleteDerivedData(of: worktree)
        }
        if deleteBranch, let branch = worktree.branch {
            await deleteMergedBranch(branch, at: main)
        }
        return true
    }

    private func deleteDerivedData(of worktree: WorktreeInfo) async {
        do {
            let count = try await provider.removeDerivedData(for: worktree.path)
            activity.log("Delete DerivedData", detail: "\(count) folders for \(worktree.title)", outcome: .success)
        } catch {
            executor.fail("Delete DerivedData", message: error.localizedDescription)
        }
    }

    private func deleteMergedBranch(_ branch: String, at main: String) async {
        let result = try? await git.run(.deleteBranch(branch, force: false), at: main)
        if result?.exitCode == 0 {
            activity.log("Delete branch \(branch)", detail: "git branch -d", outcome: .success)
        } else {
            let message = result?.failureMessage ?? "git branch -d failed."
            activity.log("Delete branch \(branch)", detail: message, outcome: .failure)
            toaster.show("Branch \(branch) kept: it is not fully merged. Delete it in the Git tab.", tint: .orange)
        }
    }
}
