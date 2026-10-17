import Foundation
import DevHubDomain

enum GitCommandEncoder {

    static func arguments(for command: GitCommand) -> [String] {
        switch command {
        case .fetchPrune:
            return ["fetch", "--prune", "origin"]
        case .pullFastForward:
            return ["pull", "--ff-only"]
        case .push(let branch, let setUpstream):
            return setUpstream ? ["push", "-u", "origin", branch] : ["push"]
        case .forcePushWithLease(let branch):
            return ["push", "--force-with-lease", "-u", "origin", branch]
        case .fetchBranch(let remote, let local):
            return ["fetch", "origin", "\(remote):\(local)"]
        case .fetchRef(let ref):
            return ["fetch", "origin", ref]
        case .rebase(let onto, let autostash):
            return autostash ? ["rebase", "--autostash", onto] : ["rebase", onto]
        case .continueRebase:
            return ["rebase", "--continue"]
        case .abort(let operation):
            return [operation, "--abort"]
        case .stashPush(let message, let includeUntracked):
            let untracked = includeUntracked ? ["--include-untracked"] : []
            let text = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return ["stash", "push"] + untracked + (text.isEmpty ? [] : ["-m", text])
        case .stashPop(let index):
            return ["stash", "pop"] + (index.map { [stashRef($0)] } ?? [])
        case .stashApply(let index):
            return ["stash", "apply", stashRef(index)]
        case .stashDrop(let index):
            return ["stash", "drop", stashRef(index)]
        case .switchBranch(let branch):
            return ["switch", branch]
        case .createTrackingBranch(let local, let remote):
            return ["switch", "--track", "-c", local, remote]
        case .deleteBranch(let branch, let force):
            return ["branch", force ? "-D" : "-d", branch]
        case .stage(let path):
            return ["add", "--", path]
        case .unstage(let path):
            return ["restore", "--staged", "--", path]
        case .restore(let path):
            return ["restore", "--", path]
        case .restoreStagedAndWorktree(let path):
            return ["restore", "--staged", "--worktree", "--", path]
        case .cleanUntracked(let path):
            return ["clean", "-f", "--", path]
        case .stageAll:
            return ["add", "-A"]
        case .unstageAll:
            return ["reset", "-q"]
        case .commit(let message, let amend):
            return ["commit", "-m", message] + (amend ? ["--amend"] : [])
        }
    }

    private static func stashRef(_ index: Int) -> String {
        "stash@{\(index)}"
    }

    static func environment(for command: GitCommand) -> [String: String] {
        switch command {
        case .continueRebase:
            return ["GIT_EDITOR": "true"]
        default:
            return [:]
        }
    }
}
