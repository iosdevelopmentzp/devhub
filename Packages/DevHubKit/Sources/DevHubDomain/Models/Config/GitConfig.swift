import Foundation

package struct GitConfig: Codable, Hashable, Sendable {
    package var remote: String? = nil
    package var baseBranch: String? = nil
    package var protectedBranches: [String]? = nil
    package var commitPrefix: CommitPrefixConfig? = nil
    package var ticketURL: String? = nil
    package var worktrees: WorktreesConfig? = nil
    package var host: GitHostConfig? = nil
    package var pullRequests: PullRequestsConfig? = nil

    package init(
        remote: String? = nil,
        baseBranch: String? = nil,
        protectedBranches: [String]? = nil,
        commitPrefix: CommitPrefixConfig? = nil,
        ticketURL: String? = nil,
        worktrees: WorktreesConfig? = nil,
        host: GitHostConfig? = nil,
        pullRequests: PullRequestsConfig? = nil
    ) {
        self.remote = remote
        self.baseBranch = baseBranch
        self.protectedBranches = protectedBranches
        self.commitPrefix = commitPrefix
        self.ticketURL = ticketURL
        self.worktrees = worktrees
        self.host = host
        self.pullRequests = pullRequests
    }
}
