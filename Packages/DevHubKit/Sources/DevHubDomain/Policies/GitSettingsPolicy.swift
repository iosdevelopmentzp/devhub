import Foundation

package enum GitSettingsPolicy {
    package static let defaultRemote = "origin"
    package static let defaultProtectedBranches = ["main", "master", "develop", "dev"]
    package static let defaultTicketPattern = #"^([A-Z][A-Z0-9]+-\d+)"#
    package static let defaultTicketFormat = "$1: "
    package static let defaultStaleDays = 14
    package static let defaultHiddenFiles = ["*Tests/*", "*Tests.swift", "*.xcodeproj/*", "*.resolved", "*.lock"]
    package static let defaultReviewCommand = "claude \"$(cat {prompt})\""

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
            ),
            hostKind: git?.host?.kind,
            hostName: meaningful(git?.host?.name),
            pullRequests: pullRequestSettings(git?.pullRequests, ai: config.ai)
        )
    }

    package static func templatePath(_ settings: PullRequestSettings, kind: CodeHostKind?) -> String {
        if let template = settings.template { return template }
        switch kind {
        case .github: return ".github/pull_request_template.md"
        case .gitlab, nil: return ".gitlab/merge_request_templates/Default.md"
        }
    }

    package static func baseRef(remote: String) -> String {
        "\(remote)/main"
    }

    private static func pullRequestSettings(_ config: PullRequestsConfig?, ai: AIConfig?) -> PullRequestSettings {
        let targets = config?.targets?.compactMap(meaningful)
        return PullRequestSettings(
            targets: targets?.isEmpty == false ? targets : nil,
            template: meaningful(config?.template),
            staleDays: config?.staleDays.map { max($0, 1) } ?? defaultStaleDays,
            hiddenFiles: config?.hiddenFiles?.compactMap(meaningful) ?? defaultHiddenFiles,
            isDraft: config?.defaults?.draft ?? false,
            deleteSourceBranch: config?.defaults?.deleteSourceBranch ?? true,
            squash: config?.defaults?.squash ?? false,
            reviewCommand: meaningful(ai?.reviewCommand) ?? defaultReviewCommand
        )
    }

    private static func meaningful(_ value: String?) -> String? {
        guard let trimmed = value?.trimmed, trimmed.isEmpty == false else { return nil }
        return trimmed
    }
}
