import Foundation

extension GitStore {
    func switchTo(_ name: String) async {
        await perform(.switchBranch(name), title: "Switch to \(name)")
    }

    func checkOutRemote(_ name: String) async {
        if branches.hasLocal(name) {
            await switchTo(name)
        } else {
            await perform(.trackRemote(name), title: "Check out \(name)")
        }
    }

    func showCheckout(of branch: GitBranch) {
        guard let path = branch.worktreePath else { return }
        selectCheckout(path)
    }

    func deleteBranch(_ branch: GitBranch) async {
        if branch.isMerged {
            await perform(.deleteBranch(branch.name, force: false), at: worktrees.mainPath, title: "Delete branch \(branch.name)")
        } else {
            setConfirmation(.deleteBranch(branch.name))
        }
    }

    func createWorktree(for name: String) async {
        setBusy("Creating worktree for \(name)")
        let created = await worktrees.createWorktree(named: name)
        setBusy(nil)
        if created {
            await refresh()
        }
    }

    func copy(_ value: String) {
        toaster.copy(value, label: value)
    }

    func openOnWeb(branch: String) {
        guard let link = session.repository else {
            projectActions.fail("Open on web", "The project has no remote called origin.")
            return
        }
        projectActions.open(link.treeURL(branch: branch), title: "Open branch on web")
    }

    func openNewRequest(branch: String) {
        guard let link = session.repository else {
            projectActions.fail("New request", "The project has no remote called origin.")
            return
        }
        let title = link.host == .gitlab ? "New merge request" : "New pull request"
        projectActions.open(link.newRequestURL(branch: branch, base: baseBranch), title: title)
    }

    func openPullRequest() {
        guard case let .found(info) = pullRequest, info.url.isEmpty == false else { return }
        projectActions.open(info.url, title: "Open \(info.label)")
    }

    func copyHash(_ commit: GitCommit) {
        toaster.copy(commit.hash, label: commit.shortHash)
    }

    func loadPullRequest(force: Bool) async {
        guard let link = session.repository, let branch = status.branch else {
            setPullRequest(nil)
            return
        }
        let key = checkoutPath + "|" + branch
        if force == false, let cached = pullRequestCache[key], Date().timeIntervalSince(cached.date) < 60 {
            setPullRequest(cached.load)
            return
        }
        let load = await hosting.load(branch: branch, repository: link, at: checkoutPath)
        guard status.branch == branch else { return }
        pullRequestCache[key] = (Date(), load)
        setPullRequest(load)
    }
}
