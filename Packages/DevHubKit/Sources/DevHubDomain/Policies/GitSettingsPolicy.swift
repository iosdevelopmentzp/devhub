import Foundation

package enum GitSettingsPolicy {
    package static let defaultRemote = "origin"
    package static let defaultProtectedBranches = ["main", "master", "develop", "dev"]
    package static let defaultTicketPattern = #"^([A-Z][A-Z0-9]+-\d+)"#
    package static let defaultTicketFormat = "$1: "

    package static func settings(for config: ProjectConfig) -> GitSettings {
        let git = config.git
        let worktrees = git?.worktrees
        return GitSettings(
            remote: meaningful(git?.remote) ?? defaultRemote,
            baseBranch: meaningful(git?.baseBranch),
            protectedBranches: git?.protectedBranches ?? defaultProtectedBranches,
            ticketPattern: meaningful(git?.commitPrefix?.pattern) ?? defaultTicketPattern,
            ticketFormat: git?.commitPrefix?.format ?? defaultTicketFormat,
            ticketURL: meaningful(git?.ticketURL),
            worktrees: WorktreeSettings(
                folder: meaningful(worktrees?.folder),
                include: worktrees?.include ?? [],
                bootstrap: meaningful(worktrees?.bootstrap),
                bootstrapMarker: meaningful(worktrees?.bootstrapMarker)
            )
        )
    }

    package static func baseRef(remote: String) -> String {
        "\(remote)/main"
    }

    private static func meaningful(_ value: String?) -> String? {
        guard let trimmed = value?.trimmed, trimmed.isEmpty == false else { return nil }
        return trimmed
    }
}
