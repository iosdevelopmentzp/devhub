import Foundation

package struct GitSettings: Hashable, Sendable {
    package var remote: String
    package var baseBranch: String?
    package var protectedBranches: [String]
    package var ticketPattern: String
    package var ticketFormat: String
    package var ticketURL: String?
    package var worktrees: WorktreeSettings
    package var hostKind: CodeHostKind?
    package var hostName: String?
    package var pullRequests: PullRequestSettings

    package static let standard = GitSettingsPolicy.settings(for: ProjectConfig())

    package init(
        remote: String,
        baseBranch: String?,
        protectedBranches: [String],
        ticketPattern: String,
        ticketFormat: String,
        ticketURL: String?,
        worktrees: WorktreeSettings,
        hostKind: CodeHostKind?,
        hostName: String?,
        pullRequests: PullRequestSettings
    ) {
        self.remote = remote
        self.baseBranch = baseBranch
        self.protectedBranches = protectedBranches
        self.ticketPattern = ticketPattern
        self.ticketFormat = ticketFormat
        self.ticketURL = ticketURL
        self.worktrees = worktrees
        self.hostKind = hostKind
        self.hostName = hostName
        self.pullRequests = pullRequests
    }
}
