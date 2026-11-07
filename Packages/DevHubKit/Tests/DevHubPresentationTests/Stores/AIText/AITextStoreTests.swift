import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct AITextStoreTests {
    private let harness = StoreHarness()
    private let summary = PullRequestSummaryFixture.request(iid: 7, source: "feature/ABC-123-short-title", state: .opened)
    private let file = PullRequestFileDiff(oldPath: "a.swift", path: "a.swift", kind: .modified, additions: 1, deletions: 0, diff: GitDiff(lines: ["+x"], droppedLines: 0, isBinary: false), isTooLarge: false)

    private var store: AITextStore {
        harness.aiText
    }

    @Test func aCommitMessageComesFromTheStagedPatch() async throws {
        harness.spies.changes.patchResult = .success("+let coins = 3")
        harness.spies.aiText.generateResult = .success("```\nfeat: add the gift value\n```")
        let message = CallbackRecorder<String>()

        store.writeCommitMessage(provider: .claude) { message.append($0) }

        try await waitUntil { store.running.isEmpty && message.values.isEmpty == false }
        #expect(message.values == ["feat: add the gift value"])
        #expect(harness.spies.changes.calls.contains(.patch(.staged, path: harness.git.checkoutPath)))
        let call = try #require(harness.spies.aiText.calls.first)
        #expect(call.prompt.hasPrefix("Write a git commit message"))
        #expect(call.command == AITextCommandPolicy.defaultClaudeCommand)
        #expect(harness.operations.latest(at: .changes)?.title == "Write a commit message with Claude Code")
        #expect(harness.operations.latest(at: .changes)?.status == .succeeded)
    }

    @Test func nothingStagedFailsTheOperationWithoutCallingTheTool() async throws {
        harness.spies.changes.patchResult = .success("  \n")

        store.writeCommitMessage(provider: .copilot) { _ in }

        try await waitUntil { store.running.isEmpty && harness.operations.latest(at: .changes)?.failureMessage != nil }
        #expect(harness.operations.latest(at: .changes)?.failureMessage == AITextError.nothingToDescribe.localizedDescription)
        #expect(harness.spies.aiText.calls.isEmpty)
        #expect(harness.lastActivity?.title == "Write a commit message with Copilot CLI failed")
    }

    @Test func theOtherToolUsesItsOwnCommand() async throws {
        harness.spies.changes.patchResult = .success("+x")

        store.writeCommitMessage(provider: .copilot) { _ in }

        try await waitUntil { store.running.isEmpty && harness.spies.aiText.calls.isEmpty == false }
        #expect(harness.spies.aiText.calls.first?.command == AITextCommandPolicy.defaultCopilotCommand)
    }

    @Test func explainKeepsTheAnswerForTheRequest() async throws {
        harness.spies.aiText.generateResult = .success("## What it changes\nAdds login.")

        store.explain(summary, description: "Adds login", files: [file], changedSinceReview: ["a.swift"], provider: .claude)
        #expect(store.explainingIDs == [7])

        try await waitUntil { store.running.isEmpty }
        #expect(store.explanations[7] == "## What it changes\nAdds login.")
        #expect(harness.spies.aiText.calls.first?.prompt.contains("describe only these files: a.swift") == true)
        #expect(harness.operations.latest(at: .pullRequest(7))?.title.hasPrefix("Explain") == true)

        store.clearExplanation(of: 7)
        #expect(store.explanations[7] == nil)
    }

    @Test func aFailedToolKeepsTheReason() async throws {
        harness.spies.aiText.generateResult = .failure(AITextError.command("Access denied by policy settings"))

        store.explain(summary, description: "", files: [file], changedSinceReview: [], provider: .copilot)

        try await waitUntil { store.running.isEmpty }
        #expect(store.explanations[7] == nil)
        #expect(harness.operations.latest(at: .pullRequest(7))?.failureMessage == "Access denied by policy settings")
    }

    @Test func aRequestDraftGetsATitleAndABody() async throws {
        harness.spies.changes.patchResult = .success("+x")
        harness.spies.aiText.generateResult = .success("ABC-123: Short title\n\n## Summary\nAdds x.")
        let draft = NewPullRequestDraft(
            origin: .header,
            sourceBranch: "feature/ABC-123-short-title",
            targets: ["main"],
            targetBranch: "main",
            title: "ABC-123: Short title",
            description: "## Summary\n",
            availableLabels: [],
            labels: [],
            isDraft: false,
            removeSourceBranch: true,
            squash: false,
            pushPlan: .none,
            isLoading: false,
            isCreating: false,
            error: nil
        )
        let texts = CallbackRecorder<String>()

        store.writePullRequest(draft, provider: .claude) { title, body in
            texts.append(title)
            texts.append(body)
        }

        try await waitUntil { store.running.isEmpty && texts.values.isEmpty == false }
        #expect(texts.values == ["ABC-123: Short title", "## Summary\nAdds x."])
        #expect(harness.spies.changes.calls.contains(.patch(.range(base: "origin/main", head: "feature/ABC-123-short-title"), path: harness.git.checkoutPath)))
        #expect(harness.operations.latest(at: .newPullRequest)?.status == .succeeded)
    }

    @Test func theDefaultToolComesFromTheSettings() {
        harness.settings.values.aiTextProvider = .copilot

        #expect(store.defaultProvider == .copilot)
    }

    @Test func aLargeDiffIsExplainedInParts() async throws {
        harness.spies.aiText.generateResult = .success("Part answer")
        let big = (0..<3).map { index in
            PullRequestFileDiff(oldPath: "f\(index).swift", path: "f\(index).swift", kind: .modified, additions: 1, deletions: 0, diff: GitDiff(lines: [String(repeating: "+x", count: 20_000)], droppedLines: 0, isBinary: false), isTooLarge: false)
        }

        store.explain(summary, description: "", files: big, changedSinceReview: [], provider: .claude)

        try await waitUntil { store.running.isEmpty }
        #expect(harness.spies.aiText.calls.count == 3)
        #expect(harness.spies.aiText.calls[1].prompt.contains("This is part 2 of 3"))
        #expect(store.explanations[7]?.hasPrefix("### Part 1 of 3\n\nPart answer") == true)
        #expect(harness.lastActivity?.detail == "3 parts")
    }
}
