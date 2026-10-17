#if DEBUG
import Foundation
import DevHubDomain

package extension PresentationAssembly {
    func debugRunGitOps(_ script: String) async {
        await worktrees.refresh()
        await config.reload()
        await git.refresh()
        await changes.refresh()
        for step in script.split(separator: ",").map(String.init) {
            let parts = step.split(separator: ":", maxSplits: 1).map(String.init)
            activity.log("Debug git", detail: step, outcome: .info)
            await debugPerform(parts[0], parts.count > 1 ? parts[1] : "")
            await debugSettle()
        }
        activity.log("Debug git", detail: "Script finished", outcome: .success)
    }
}

private extension PresentationAssembly {
    func debugPerform(_ name: String, _ argument: String) async {
        switch name {
        case "sleep": try? await Task.sleep(for: .seconds(Double(argument) ?? 1))
        case "fetch": git.fetch()
        case "pull": git.pull()
        case "push": git.push()
        case "forcepush": git.forcePush()
        case "rebase": git.rebaseOnBase()
        case "continueop": git.continueRebase()
        case "abortop": git.abortOperation()
        case "updatebase": git.updateBase()
        case "stash": git.stash(message: argument)
        case "popstash": git.popStash()
        case "switch": git.switchTo(argument, plan: .switchOnly)
        case "switchstash": git.switchTo(argument, plan: .stashSwitchPop)
        case "update": git.localBranch(named: argument).map(git.update)
        case "delete-branch": git.localBranch(named: argument).map { git.delete($0, force: false) }
        case "checkout-remote": git.state?.remoteBranches.first { $0.name == argument }.map(git.checkOut)
        case "select": git.selectCheckout(argument == "main" ? nil : argument)
        case "stage": change(argument).map(changes.stage)
        case "unstage": change(argument).map(changes.unstage)
        case "discard": change(argument).map(changes.discard)
        case "stageall": changes.stageAll()
        case "unstageall": changes.unstageAll()
        case "commit", "commitpush", "amend":
            changes.message = argument
            changes.amend = name == "amend"
            changes.commit(thenPush: name == "commitpush")
        case "action": await debugRunAction(argument, prompt: false)
        case "wt-create": _ = await worktrees.createAndBootstrap(branch: argument)
        case "wt-delete": worktrees.worktrees.first { $0.branch == argument }.map { worktrees.delete(id: $0.id, deleteDerivedData: false, deleteBranch: true) }
        case "wt-prune": worktrees.prune()
        case "wt-fetch": worktrees.fetchAndRefresh()
        default: activity.log("Debug git", detail: "Unknown step \(name)", outcome: .failure)
        }
    }

    func change(_ path: String) -> GitFileChange? {
        changes.changes.first { $0.path == path }
    }

    func debugSettle() async {
        for _ in 0..<600 {
            try? await Task.sleep(for: .milliseconds(100))
            let isIdle = git.isBusy == false && changes.busyTitle == nil && worktrees.busyIDs.isEmpty && worktrees.isFetching == false && worktrees.bootstrappingIDs.isEmpty
            guard isIdle else { continue }
            await worktrees.refresh()
            await git.refresh()
            await changes.refresh()
            return
        }
        activity.log("Debug git", detail: "A step did not finish in 60 s", outcome: .failure)
    }
}
#endif
