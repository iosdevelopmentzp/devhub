import Foundation

package struct InstalledBuild: Codable, Equatable, Sendable {
    package var commit: String
    package var branch: String
    package var source: String
    package var installedAt: Date

    package init(commit: String, branch: String, source: String, installedAt: Date) {
        self.commit = commit
        self.branch = branch
        self.source = source
        self.installedAt = installedAt
    }

    package var shortCommit: String {
        String(commit.prefix(7))
    }

    package var remoteBranch: String {
        "origin/\(branch)"
    }
}
