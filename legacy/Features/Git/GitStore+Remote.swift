import Foundation

extension GitStore {
    @discardableResult
    func perform(_ command: GitCommand, at path: String? = nil, title: String? = nil, announce: Bool = true) async -> Bool {
        let target = path ?? checkoutPath
        let name = title ?? command.title
        setBusy(name)
        let result = await executor.perform(command, at: target, title: name)
        setBusy(nil)
        if announce {
            await refresh(reloadCheckouts: false)
            announceChange()
        }
        return result != nil
    }

    func fetch() async {
        await perform(.fetch(prune: false))
    }

    func pull() async {
        await perform(.pull)
    }

    func push() async {
        await perform(.push(upstreamBranch: hasUpstream ? nil : status.branch))
    }

    func askForcePush() {
        setConfirmation(.forcePush)
    }

    func askRebase() {
        setConfirmation(.rebase)
    }

    func cancelConfirmation() {
        setConfirmation(nil)
    }

    func confirm() async {
        guard let pending = confirmation else { return }
        setConfirmation(nil)
        switch pending {
        case .forcePush:
            await perform(.forcePush)
        case .rebase:
            await rebaseOnBase()
        case let .discard(path, group):
            await discard(path: path, group: group)
        case let .deleteBranch(name):
            await perform(.deleteBranch(name, force: true), at: worktrees.mainPath, title: "Delete branch \(name)")
        }
    }

    func updateBase() async {
        await update(branch: baseLocalName)
    }

    func update(branch name: String) async {
        if let path = branches.local(named: name)?.worktreePath {
            await perform(.pull, at: path, title: "Update \(name)")
        } else {
            await perform(.updateBranch(name), title: "Update \(name)")
        }
    }

    func stash() async {
        await perform(.stash)
    }

    func popStash() async {
        await perform(.popStash)
    }

    func continueOperation() async {
        guard let operation = details.operation else { return }
        await perform(.continueOperation(operation))
    }

    func abortOperation() async {
        guard let operation = details.operation else { return }
        await perform(.abortOperation(operation))
    }

    func openTerminal() {
        projectActions.openTerminal(at: checkoutPath)
    }

    private func rebaseOnBase() async {
        let path = checkoutPath
        setBusy("Rebase on \(baseBranch)")
        defer { setBusy(nil) }
        guard await executor.perform(.fetch(prune: false), at: path) != nil else { return }
        _ = await executor.perform(.rebase(onto: baseBranch), at: path)
        await refresh(reloadCheckouts: false)
        announceChange()
    }
}
