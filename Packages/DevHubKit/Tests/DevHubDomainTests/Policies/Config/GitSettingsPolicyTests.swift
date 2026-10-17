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
}
