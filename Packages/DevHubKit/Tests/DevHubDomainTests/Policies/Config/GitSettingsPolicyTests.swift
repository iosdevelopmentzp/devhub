import Foundation
import Testing
@testable import DevHubDomain

@Suite struct GitSettingsPolicyTests {
    @Test func anEmptyConfigGivesTheDefaults() {
        let settings = GitSettingsPolicy.settings(for: ProjectConfig())

        #expect(settings.remote == "origin")
        #expect(settings.baseBranch == nil)
        #expect(settings.protectedBranches == ["main", "master", "develop", "dev"])
        #expect(settings.ticketPattern == #"^([A-Z][A-Z0-9]+-\d+)"#)
        #expect(settings.ticketFormat == "$1: ")
        #expect(settings.ticketURL == nil)
        #expect(settings.worktrees == .standard)
        #expect(GitSettings.standard == settings)
    }

    @Test func configValuesWin() {
        let config = ProjectConfig(git: GitConfig(
            remote: "upstream",
            baseBranch: "upstream/develop",
            protectedBranches: ["release"],
            commitPrefix: CommitPrefixConfig(pattern: "^(T-\\d+)", format: "[$1] "),
            ticketURL: "https://tracker.example.com/{key}",
            worktrees: WorktreesConfig(folder: "../wt", include: [".env"], bootstrap: "scripts/setup.sh", bootstrapMarker: "Pods")
        ))

        let settings = GitSettingsPolicy.settings(for: config)

        #expect(settings.remote == "upstream")
        #expect(settings.baseBranch == "upstream/develop")
        #expect(settings.protectedBranches == ["release"])
        #expect(settings.ticketPattern == "^(T-\\d+)")
        #expect(settings.ticketFormat == "[$1] ")
        #expect(settings.ticketURL == "https://tracker.example.com/{key}")
        #expect(settings.worktrees == WorktreeSettings(folder: "../wt", include: [".env"], bootstrap: "scripts/setup.sh", bootstrapMarker: "Pods"))
    }

    @Test func blankStringsCountAsMissing() {
        let config = ProjectConfig(git: GitConfig(remote: " ", baseBranch: "", ticketURL: "", worktrees: WorktreesConfig(folder: "", bootstrap: " ")))

        let settings = GitSettingsPolicy.settings(for: config)

        #expect(settings.remote == "origin")
        #expect(settings.baseBranch == nil)
        #expect(settings.ticketURL == nil)
        #expect(settings.worktrees.folder == nil)
        #expect(settings.worktrees.bootstrap == nil)
    }

    @Test func theFallbackBaseUsesTheRemote() {
        #expect(GitSettingsPolicy.baseRef(remote: "upstream") == "upstream/main")
    }

    @Test func theGitFieldsDecode() throws {
        let object: [String: Any] = ["git": ["remote": "upstream", "protectedBranches": ["release"], "ticketURL": "https://tracker.example.com/{key}"]]

        let config = try ConfigDecoding.decode(ProjectConfig.self, from: object)

        #expect(config.git?.remote == "upstream")
        #expect(config.git?.protectedBranches == ["release"])
        #expect(config.git?.ticketURL == "https://tracker.example.com/{key}")
    }

    @Test func pullRequestSettingsHaveDefaults() {
        let settings = GitSettingsPolicy.settings(for: ProjectConfig()).pullRequests

        #expect(settings == PullRequestSettings(
            targets: nil,
            template: nil,
            staleDays: 14,
            hiddenFiles: [],
            isDraft: false,
            deleteSourceBranch: true,
            squash: false,
            aiCommands: [.claude: #"claude "$(cat {prompt})""#, .copilot: #"copilot -i "$(cat {prompt})""#],
            aiTextCommands: AITextCommandPolicy.commands(nil)
        ))
    }

    @Test func fileGroupsKeepNamedGroupsWithPatternsOnce() {
        let config = ProjectConfig(git: GitConfig(pullRequests: PullRequestsConfig(fileGroups: [
            FileGroupConfig(name: " Tests ", patterns: ["*Tests/*", " ", "*Tests.swift"], hidden: true),
            FileGroupConfig(name: "App", patterns: ["*/App/*"]),
            FileGroupConfig(name: "Tests", patterns: ["Other/*"]),
            FileGroupConfig(name: " ", patterns: ["*.lock"]),
            FileGroupConfig(name: "Empty", patterns: [" "]),
            FileGroupConfig(name: "None"),
        ])))

        #expect(GitSettingsPolicy.settings(for: config).pullRequests.fileGroups == [
            PullRequestFileGroup(name: "Tests", patterns: ["*Tests/*", "*Tests.swift"], isHiddenByDefault: true),
            PullRequestFileGroup(name: "App", patterns: ["*/App/*"], isHiddenByDefault: false),
        ])
        #expect(GitSettingsPolicy.settings(for: ProjectConfig()).pullRequests.fileGroups.isEmpty)
    }

    @Test func anEmptyHiddenFilesListHidesNothing() {
        let config = ProjectConfig(git: GitConfig(pullRequests: PullRequestsConfig(hiddenFiles: [])))

        #expect(GitSettingsPolicy.settings(for: config).pullRequests.hiddenFiles.isEmpty)
    }

    @Test func pullRequestSettingsComeFromConfig() {
        let config = ProjectConfig(
            git: GitConfig(pullRequests: PullRequestsConfig(
                targets: ["main", " "],
                template: "docs/pr.md",
                staleDays: 3,
                hiddenFiles: ["Generated/*", " "],
                defaults: PullRequestDefaultsConfig(draft: true, deleteSourceBranch: false, squash: true),
                reviewQueue: "assigned"
            )),
            ai: AIConfig(reviewCommand: "codex {prompt}")
        )

        let settings = GitSettingsPolicy.settings(for: config).pullRequests

        #expect(settings == PullRequestSettings(
            targets: ["main"],
            template: "docs/pr.md",
            staleDays: 3,
            hiddenFiles: ["Generated/*"],
            isDraft: true,
            deleteSourceBranch: false,
            squash: true,
            aiCommands: [.claude: "codex {prompt}", .copilot: #"copilot -i "$(cat {prompt})""#],
            aiTextCommands: AITextCommandPolicy.commands(nil),
            reviewQueue: .assigned
        ))
    }

    @Test func theReviewQueueIsOpenByDefault() {
        #expect(GitSettingsPolicy.settings(for: ProjectConfig()).pullRequests.reviewQueue == .open)
    }

    @Test func aiCommandsComeFromTheCommandsMapBeforeTheOldReviewCommand() {
        let both = AIConfig(reviewCommand: "old {prompt}", commands: ["claude": "new {prompt}", "copilot": "cop {prompt}", "other": "x"])
        let blank = AIConfig(reviewCommand: " ", commands: ["copilot": " "])

        #expect(GitSettingsPolicy.aiCommands(both) == [.claude: "new {prompt}", .copilot: "cop {prompt}"])
        #expect(GitSettingsPolicy.aiCommands(blank) == [.claude: GitSettingsPolicy.defaultReviewCommand, .copilot: GitSettingsPolicy.defaultCopilotCommand])
        #expect(GitSettingsPolicy.aiCommands(nil)[.copilot] == #"copilot -i "$(cat {prompt})""#)
    }

    @Test func theTemplateDependsOnTheHost() {
        let settings = GitSettings.standard.pullRequests

        #expect(GitSettingsPolicy.templatePath(settings, kind: .github) == ".github/pull_request_template.md")
        #expect(GitSettingsPolicy.templatePath(settings, kind: .gitlab) == ".gitlab/merge_request_templates/Default.md")
    }
}
