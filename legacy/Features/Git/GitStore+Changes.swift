import Foundation

extension GitStore {
    func diffKey(_ change: GitChange, _ group: GitChange.Group) -> String {
        "\(group.rawValue)|\(change.path)"
    }

    func toggleDiff(_ change: GitChange, in group: GitChange.Group) async {
        let key = diffKey(change, group)
        if expandedDiff == key {
            setExpandedDiff(nil)
            return
        }
        setExpandedDiff(key)
        do {
            storeDiff(try await provider.diff(at: checkoutPath, change: change, group: group), for: key)
        } catch {
            storeDiff(GitDiff(lines: [error.localizedDescription], isBinary: false, hiddenLineCount: 0), for: key)
            executor.fail("Show diff", message: error.localizedDescription)
        }
    }

    func stage(_ change: GitChange) async {
        await changeIndex(.stage([change.path]))
    }

    func unstage(_ change: GitChange) async {
        await changeIndex(.unstage([change.path]))
    }

    func stageAll() async {
        await changeIndex(.stageAll)
    }

    func unstageAll() async {
        await changeIndex(.unstageAll)
    }

    func askDiscard(_ change: GitChange, in group: GitChange.Group) {
        setConfirmation(.discard(path: change.path, group: group))
    }

    func discard(path: String, group: GitChange.Group) async {
        guard let change = status.changes.first(where: { $0.path == path }) else { return }
        let command: GitCommand
        switch group {
        case .untracked: command = .cleanFile(path)
        case .unstaged: command = .restore(path)
        case .staged: command = change.index == "A" ? .removeAdded(path) : .restoreStaged(path)
        case .conflict: return
        }
        clearDiffs()
        await perform(command, title: "Discard \(change.fileName)")
    }

    func openInEditor(_ change: GitChange) {
        projectActions.openInEditor(at: checkoutPath + "/" + change.path)
    }

    func commit(thenPush: Bool) async {
        let message = commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard message.isEmpty == false || amend else { return }
        let path = checkoutPath
        setBusy(amend ? "Amend commit" : "Commit")
        defer { setBusy(nil) }
        guard await executor.perform(.commit(message: message, amend: amend), at: path) != nil else { return }
        commitMessage = ""
        lastPrefix = nil
        amend = false
        if thenPush {
            _ = await executor.perform(.push(upstreamBranch: hasUpstream ? nil : status.branch), at: path)
        }
        clearDiffs()
        await refresh(reloadCheckouts: false)
        announceChange()
    }

    private func changeIndex(_ command: GitCommand) async {
        clearDiffs()
        await perform(command, announce: false)
        await refresh(reloadCheckouts: false)
    }
}
