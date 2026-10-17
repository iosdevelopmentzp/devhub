import Foundation

package enum GitCommand: Hashable, Sendable {
    case fetchPrune(remote: String)
    case pullFastForward
    case push(branch: String, setUpstream: Bool, remote: String)
    case forcePushWithLease(branch: String, remote: String)
    case fetchBranch(source: String, local: String, remote: String)
    case fetchRef(String, remote: String)
    case rebase(onto: String, autostash: Bool)
    case continueRebase
    case abort(operation: String)
    case stashPush(message: String?, includeUntracked: Bool)
    case stashPop(index: Int?)
    case stashApply(index: Int)
    case stashDrop(index: Int)
    case switchBranch(String)
    case createTrackingBranch(local: String, remote: String)
    case deleteBranch(String, force: Bool)
    case stage(path: String)
    case unstage(path: String)
    case restore(path: String)
    case restoreStagedAndWorktree(path: String)
    case cleanUntracked(path: String)
    case stageAll
    case unstageAll
    case commit(message: String, amend: Bool)
}
