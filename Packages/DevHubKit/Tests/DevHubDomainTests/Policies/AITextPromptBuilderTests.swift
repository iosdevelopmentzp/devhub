import Foundation
import Testing
@testable import DevHubDomain

@Suite struct AITextPromptBuilderTests {
    private let file = PullRequestFileDiff(oldPath: "a.swift", path: "a.swift", kind: .modified, additions: 1, deletions: 1, diff: GitDiff(lines: ["-old", "+new"], droppedLines: 0, isBinary: false), isTooLarge: false)

    @Test func theCommitPromptHasTheRulesTheSubjectsAndTheDiff() {
        let prompt = AITextPromptBuilder.commitMessage(patch: "+let coins = 3", recentSubjects: ["feat: add calls", "fix: crash"], branch: "feature/ABC-123-short-title")

        #expect(prompt.hasPrefix("Write a git commit message"))
        #expect(prompt.contains("Branch: feature/ABC-123-short-title"))
        #expect(prompt.contains("- feat: add calls\n- fix: crash"))
        #expect(prompt.contains("```diff\n+let coins = 3\n```"))
    }

    @Test func theRequestPromptNamesTheBranchesTheTemplateAndTheNoun() {
        let prompt = AITextPromptBuilder.pullRequest(patch: "+x", commits: [], template: "## Summary\n", currentTitle: "ABC-123: Short title", source: "feature/ABC-123-short-title", target: "main", noun: "merge request")

        #expect(prompt.hasPrefix("Write the title and the description of a merge request"))
        #expect(prompt.contains("Target branch: main"))
        #expect(prompt.contains("Current title: ABC-123: Short title"))
        #expect(prompt.contains("Commits:\n(none)"))
        #expect(prompt.contains("Template:\n## Summary"))
    }

    @Test func explainAsksForTheChangedFilesOnlyAfterAReview() {
        let plain = AITextPromptBuilder.explain(title: "Login", description: "", files: [file], changedSinceReview: [], noun: "pull request")
        let reviewed = AITextPromptBuilder.explain(title: "Login", description: "Adds login", files: [file], changedSinceReview: ["a.swift"], noun: "pull request")

        #expect(plain.contains("## Changed since my review") == false)
        #expect(plain.contains("Description:\n(none)"))
        #expect(reviewed.contains("## Changed since my review"))
        #expect(reviewed.contains("describe only these files: a.swift"))
    }

    @Test func aFileDiffBecomesAPatch() {
        let large = PullRequestFileDiff(oldPath: "b.swift", path: "c.swift", kind: .renamed, additions: 900, deletions: 10, diff: GitDiff(lines: [], droppedLines: 0, isBinary: false), isTooLarge: true)

        let patch = AITextPromptBuilder.patch(of: [file, large])

        #expect(patch == "--- a/a.swift\n+++ b/a.swift\n-old\n+new\n--- a/b.swift\n+++ b/c.swift\n(diff too large, 900 added and 10 removed lines)")
    }

    @Test func aLongPatchIsCutWithANote() {
        let patch = String(repeating: "x", count: AITextPromptBuilder.patchLimit + 10)

        let limited = AITextPromptBuilder.limited(patch)

        #expect(limited.hasPrefix(String(repeating: "x", count: 100)))
        #expect(limited.hasSuffix("(the rest of the diff is cut: 10 more characters)"))
        #expect(AITextPromptBuilder.limited("short") == "short")
    }
}
