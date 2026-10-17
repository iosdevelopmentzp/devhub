import Foundation

package struct GitRepositoryState: Hashable, Sendable {
    package var snapshot: GitSnapshot
    package var localBranches: [GitBranch]
    package var remoteBranches: [RemoteBranch]
    package var history: [GitCommit]
    package var stashes: [GitStash]

    package init(
        snapshot: GitSnapshot,
        localBranches: [GitBranch],
        remoteBranches: [RemoteBranch],
        history: [GitCommit],
        stashes: [GitStash] = []
    ) {
        self.snapshot = snapshot
        self.localBranches = localBranches
        self.remoteBranches = remoteBranches
        self.history = history
        self.stashes = stashes
    }
}
