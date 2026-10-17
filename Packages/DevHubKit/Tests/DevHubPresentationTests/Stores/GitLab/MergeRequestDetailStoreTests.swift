import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct MergeRequestDetailStoreTests {
    private let harness = StoreHarness()
    private let remote = CodeHost.gitLabSample
    private let details = MergeRequestDetails(
        description: "Adds login",
        threads: [
            MergeRequestThread(id: "t1", noteID: nil, author: "sam", body: "Move", filePath: "a.swift", line: 4, isOnOldLine: true, replies: []),
            MergeRequestThread(id: "t2", noteID: nil, author: "sam", body: "General", filePath: nil, line: nil, isOnOldLine: false, replies: []),
        ]
    )
    private let files = [
        MergeRequestFileDiff(
            oldPath: "a.swift",
            path: "a.swift",
            kind: .modified,
            additions: 1,
            deletions: 0,
            diff: GitDiff(lines: ["+x"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
    ]

    private var store: MergeRequestDetailStore {
        harness.mergeRequestDetails
    }

    private func script() {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.mergeRequests.detailsResult = .success(details)
        harness.spies.mergeRequests.diffsResult = .success(files)
    }

    @Test func loadReadsDetailsAndDiffsOnce() async {
        script()

        await store.load(7)
        await store.load(7)

        #expect(store.details[7] == details)
        #expect(store.diffs[7] == files)
        #expect(store.errors[7] == nil)
        #expect(store.isLoaded(7))
        #expect(Set(harness.spies.mergeRequests.calls) == [.details(iid: 7, repository: remote), .diffs(iid: 7, repository: remote)])
        #expect(harness.spies.mergeRequests.calls.count == 2)
    }

    @Test func aFailureIsKeptPerRequestAndReloadRetries() async {
        script()
        harness.spies.mergeRequests.diffsResult = .failure(MergeRequestError.command("boom"))

        await store.load(7)

        #expect(store.errors[7] == "boom")
        #expect(store.isLoaded(7) == false)

        harness.spies.mergeRequests.diffsResult = .success(files)
        await store.reload(7)

        #expect(store.errors[7] == nil)
        #expect(store.isLoaded(7))
    }

    @Test func toggleFileKeepsSeveralFilesOpenPerRequest() {
        store.toggleFile("a.swift", of: 7)
        store.toggleFile("b.swift", of: 7)
        store.toggleFile("x.swift", of: 8)

        #expect(store.expandedFiles(of: 7) == ["a.swift", "b.swift"])
        #expect(store.expandedFiles(of: 8) == ["x.swift"])

        store.toggleFile("a.swift", of: 7)
        #expect(store.expandedFiles(of: 7) == ["b.swift"])
    }

    @Test func expandAllOpensTheFilesNotViewedAndCollapseAllClosesThem() async {
        script()
        harness.spies.mergeRequests.diffsResult = .success(files + [MergeRequestFileDiff(oldPath: "b.swift", path: "b.swift", kind: .added, additions: 1, deletions: 0, diff: GitDiff(lines: ["+y"], droppedLines: 0, isBinary: false), isTooLarge: false)])
        await store.load(7)
        store.toggleViewed("b.swift", of: 7)

        store.expandAllFiles(of: 7)
        #expect(store.expandedFiles(of: 7) == ["a.swift"])

        store.collapseAllFiles(of: 7)
        #expect(store.expandedFiles(of: 7).isEmpty)
    }

    @Test func markingAFileViewedFoldsItAndUnmarkingKeepsItFolded() {
        store.toggleFile("a.swift", of: 7)

        store.toggleViewed("a.swift", of: 7)
        #expect(store.review(of: 7).viewedFiles == ["a.swift"])
        #expect(store.expandedFiles(of: 7).isEmpty)

        store.toggleViewed("a.swift", of: 7)
        #expect(store.review(of: 7).viewedFiles.isEmpty)
        #expect(store.expandedFiles(of: 7).isEmpty)
    }

    @Test func showInDiffOpensTheFileAndFocusesTheLine() async {
        script()
        await store.load(7)

        store.showInDiff(threadID: "t1", of: 7)

        #expect(store.expandedFiles(of: 7) == ["a.swift"])
        #expect(store.focus(of: 7) == DiffFocus(requestID: 7, path: "a.swift", line: 4, isOld: true))
        #expect(store.focus(of: 8) == nil)

        store.toggleFile("x.swift", of: 8)
        #expect(store.focus(of: 7) != nil)

        store.toggleFile("b.swift", of: 7)
        #expect(store.focus == nil)

        store.showInDiff(threadID: "t2", of: 7)
        #expect(store.expandedFiles(of: 7) == ["a.swift", "b.swift"])
        #expect(store.focus == nil)
    }

    @Test func showInDiffOpensTheThreadUnderItsLine() async {
        script()
        await store.load(7)

        store.showInDiff(threadID: "t1", of: 7)

        #expect(store.review(of: 7).openDiffThreads == ["t1"])
    }

    @Test func threadsInTheDiffFoldOneByOneOrAllTogether() async {
        script()
        await store.load(7)

        store.toggleDiffThread("t1")
        #expect(store.openDiffThreads == ["t1"])
        store.toggleDiffThread("t1")
        #expect(store.openDiffThreads.isEmpty)

        store.toggleThreadsInDiff()
        #expect(store.review(of: 7).showsThreadsInDiff == false)

        store.openAllDiffThreads(of: 7)
        #expect(store.showsThreadsInDiff)
        #expect(store.openDiffThreads == ["t1", "t2"])

        store.foldAllDiffThreads(of: 7)
        #expect(store.openDiffThreads.isEmpty)
    }

    @Test func aCancelledLoadLeavesNoError() async {
        script()
        harness.spies.mergeRequests.detailsResult = .failure(CancellationError())

        await store.load(7)

        #expect(store.errors[7] == nil)
        #expect(store.isLoaded(7) == false)
    }

    @Test func resolveAndReplyCallGitLabAndReloadTheDetails() async throws {
        script()
        await store.load(7)

        store.resolveThread("t1", of: 7)
        #expect(store.busyThreads == ["t1"])
        try await waitUntil { store.busyThreads.isEmpty && harness.spies.mergeRequests.calls.count == 5 }
        #expect(harness.spies.mergeRequests.calls.contains(.resolveThread(id: "t1", repository: remote)))
        #expect(harness.lastActivity?.title == "Resolved a thread of !7")

        store.reply("  ", to: "t1", of: 7)
        #expect(store.busyThreads.isEmpty)

        store.reply(" Looks good ", to: "t2", of: 7)
        try await waitUntil { store.busyThreads.isEmpty && harness.spies.mergeRequests.calls.count == 8 }
        #expect(harness.spies.mergeRequests.calls.contains(.reply(threadID: "t2", body: "Looks good", iid: 7, repository: remote)))
    }

    @Test func aFailedThreadActionIsLogged() async throws {
        script()
        await store.load(7)
        harness.spies.mergeRequests.actionError = MergeRequestError.command("boom")

        store.resolveThread("t1", of: 7)
        try await waitUntil { store.busyThreads.isEmpty }

        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.spies.mergeRequests.calls.count == 3)
    }

    @Test func projectChangedClearsTheCache() async {
        script()
        await store.load(7)
        store.toggleFile("a.swift", of: 7)
        store.toggleViewed("b.swift", of: 7)

        harness.events.post(.projectChanged)

        #expect(store.details.isEmpty)
        #expect(store.diffs.isEmpty)
        #expect(store.expandedFiles(of: 7).isEmpty)
        #expect(store.review(of: 7) == .initial)
    }

    // MARK: Review prompt

    @Test func reviewPromptHoldsTheOpenThreadsAndReturnsTheFile() async {
        script()
        harness.spies.reviewPrompts.saveResult = .success("/tmp/prompts/mr-7.md")
        let summary = MergeRequestSummaryFixture.request(iid: 7, source: "feature/login", state: .opened)

        let path = await store.writeReviewPrompt(for: summary)

        #expect(path == "/tmp/prompts/mr-7.md")
        #expect(harness.spies.reviewPrompts.calls == [.save(ReviewPromptBuilder.prompt(for: summary, threads: details.threads), iid: 7)])
    }

    @Test func reviewPromptWithoutOpenThreadsWritesNothing() async {
        script()
        harness.spies.mergeRequests.detailsResult = .success(MergeRequestDetails(description: "", threads: []))

        let path = await store.writeReviewPrompt(for: MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened))

        #expect(path == nil)
        #expect(harness.spies.reviewPrompts.calls.isEmpty)
        #expect(harness.lastActivity?.title == "!7 has no open threads")
    }

    @Test func reviewPromptFailuresAreLogged() async {
        script()
        harness.spies.reviewPrompts.saveResult = .failure(TestError.scripted("disk full"))

        let path = await store.writeReviewPrompt(for: MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened))

        #expect(path == nil)
        #expect(harness.lastActivity?.title == "Cannot write the review prompt of !7")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func reviewPromptReportsUnreadableDetails() async {
        script()
        harness.spies.mergeRequests.detailsResult = .failure(TestError.scripted("403"))

        let path = await store.writeReviewPrompt(for: MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened))

        #expect(path == nil)
        #expect(harness.lastActivity?.title == "Cannot read the threads of !7")
    }
}
