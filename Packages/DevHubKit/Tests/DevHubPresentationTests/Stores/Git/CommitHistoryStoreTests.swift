import Foundation
import Testing
import DevHubDomain
import DevHubMocks
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct CommitHistoryStoreTests {
    private let harness = StoreHarness()
    private let path = ProjectSample.path
    private let commit = GitCommit(hash: "a1b2c3", shortHash: "a1b", author: "kim", date: nil, subject: "ABC-1: Login", isPushed: true)
    private let file = GitCommitFile(path: "App/Login.swift", originalPath: nil, kind: .modified)

    private var store: CommitHistoryStore {
        harness.history
    }

    private func loadBranch() async {
        harness.spies.git.stateResult = .success(GitStateSample.state)
        await harness.git.refresh()
    }

    @Test func scopeStartsWithAllAndIsRemembered() {
        #expect(store.scope == .all)

        store.scope = .branch

        #expect(harness.store.string(forKey: "git.historyScope") == "This branch")
        #expect(StoreHarness(store: harness.store).history.scope == .branch)
    }

    @Test func branchCommitsAreReadAgainstTheBaseRef() async {
        await loadBranch()
        harness.spies.changes.branchCommitsResult = .success([commit])

        await store.refreshBranchCommits()

        #expect(store.branchCommits == [commit])
        #expect(store.hasLoadedBranch)
        #expect(store.branchError == nil)
        #expect(harness.spies.changes.calls == [.branchCommits(base: "origin/dev", path: path)])
    }

    @Test func aFailedBranchReadKeepsTheError() async {
        harness.spies.changes.branchCommitsResult = .failure(TestError.scripted("bad revision"))

        await store.refreshBranchCommits()

        #expect(store.branchError == TestError.scripted("bad revision").localizedDescription)
        #expect(store.hasLoadedBranch)
    }

    @Test func expandingACommitReadsItsFilesOnce() async throws {
        harness.spies.changes.commitFilesResult = .success([file])

        store.toggleRow("a1b2c3", hash: "a1b2c3")
        try await waitUntil { store.files["a1b2c3"] == [file] && store.containingBranches["a1b2c3"] != nil }
        store.toggleRow("a1b2c3", hash: "a1b2c3")
        store.toggleRow("a1b2c3", hash: "a1b2c3")

        #expect(store.expandedRow == "a1b2c3")
        #expect(Set(harness.spies.changes.calls) == [.commitFiles(hash: "a1b2c3", path: path), .branchesContaining(hash: "a1b2c3", path: path)])
        #expect(harness.spies.changes.calls.count == 2)
    }

    @Test func expandingACommitReadsTheBranchesThatContainItOnce() async throws {
        let refs = [GitCommitRef(kind: .localBranch, name: "main"), GitCommitRef(kind: .remoteBranch, name: "origin/dev")]
        harness.spies.changes.branchesContainingResult = .success(refs)

        store.toggleRow("a1b2c3", hash: "a1b2c3")
        try await waitUntil { store.containingBranches["a1b2c3"] == refs }

        harness.events.post(.branchesChanged)
        #expect(store.containingBranches.isEmpty)
    }

    @Test func expandingAStashReadsItsFilesAndDiffsWithTheStashCommands() async throws {
        let stash = GitStash(index: 0, hash: "s1s1s1", branch: "dev", message: "wip", date: nil)
        let untracked = GitCommitFile(path: "App/New.swift", originalPath: nil, kind: .untracked)
        let diff = GitDiff(lines: ["+new"], droppedLines: 0, isBinary: false)
        harness.spies.changes.stashFilesResult = .success([file, untracked])
        harness.spies.changes.stashDiffResult = .success(diff)
        let key = CommitFileKey(hash: "s1s1s1", path: untracked.path)

        store.toggleStash(stash)
        try await waitUntil { store.files["s1s1s1"] == [file, untracked] }
        store.toggleFile(untracked, of: "s1s1s1")
        try await waitUntil { store.diffs[key] == diff }
        store.toggleStash(stash)

        #expect(store.expandedRow == nil)
        #expect(CommitHistoryStore.stashRowID(stash) == "stash:s1s1s1")
        #expect(harness.spies.changes.calls == [.stashFiles(hash: "s1s1s1", path: path), .stashDiff(hash: "s1s1s1", file: untracked, path: path)])
    }

    @Test func expandingAnotherCommitClosesTheFirst() {
        store.toggleRow("a1b2c3", hash: "a1b2c3")
        store.toggleRow("d4e5f6", hash: "d4e5f6")

        #expect(store.expandedRow == "d4e5f6")
    }

    @Test func twoReflogRowsOfOneCommitOpenApartAndShareTheFiles() async throws {
        harness.spies.changes.commitFilesResult = .success([file])

        store.toggleRow("HEAD@{0}", hash: "a1b2c3")
        try await waitUntil { store.files["a1b2c3"] == [file] && store.containingBranches["a1b2c3"] != nil }
        store.toggleRow("HEAD@{1}", hash: "a1b2c3")

        #expect(store.expandedRow == "HEAD@{1}")
        #expect(harness.spies.changes.calls.filter { $0 == .commitFiles(hash: "a1b2c3", path: path) }.count == 1)
        #expect(harness.spies.changes.calls.count == 2)
    }

    @Test func reflogIsReadFromTheCheckout() async {
        let entry = GitReflogEntry(index: 0, hash: "a1b2c3", shortHash: "a1b", date: nil, action: "commit", message: "ABC-1: Login")
        harness.spies.changes.reflogResult = .success([entry])

        await store.refreshReflog()

        #expect(store.reflog == [entry])
        #expect(store.hasLoadedReflog)
        #expect(harness.spies.changes.calls == [.reflog(path: path)])
    }

    @Test func aFailedReflogReadKeepsTheError() async {
        harness.spies.changes.reflogResult = .failure(TestError.scripted("no reflog"))

        await store.refreshReflog()

        #expect(store.reflogError == TestError.scripted("no reflog").localizedDescription)
    }

    @Test func aBranchChangeReloadsALoadedReflog() async throws {
        await store.refreshReflog()
        let entry = GitReflogEntry(index: 0, hash: "a1b2c3", shortHash: "a1b", date: nil, action: "commit", message: "ABC-1: Login")
        harness.spies.changes.reflogResult = .success([entry])

        harness.events.post(.branchesChanged)

        try await waitUntil { store.reflog == [entry] }
    }

    @Test func aFailedFileReadIsShownOnTheCommit() async {
        harness.spies.changes.commitFilesResult = .failure(TestError.scripted("bad object"))

        await store.loadFiles("a1b2c3")

        #expect(store.fileErrors["a1b2c3"] == TestError.scripted("bad object").localizedDescription)
        #expect(store.files["a1b2c3"] == nil)
    }

    @Test func openingAFileReadsItsDiff() async throws {
        let diff = GitDiff(lines: ["+a"], droppedLines: 0, isBinary: false)
        harness.spies.changes.commitDiffResult = .success(diff)
        let key = CommitFileKey(hash: "a1b2c3", path: file.path)

        store.toggleFile(file, of: "a1b2c3")
        try await waitUntil { store.diffs[key] == diff }

        #expect(store.expandedFiles == [key])
        #expect(harness.spies.changes.calls == [.commitDiff(hash: "a1b2c3", file: file, path: path)])
        store.toggleFile(file, of: "a1b2c3")
        #expect(store.expandedFiles.isEmpty)
    }

    @Test func aFailedDiffClosesTheFileAndLogs() async throws {
        harness.spies.changes.commitDiffResult = .failure(TestError.scripted("boom"))

        store.toggleFile(file, of: "a1b2c3")
        try await waitUntil { store.expandedFiles.isEmpty }

        #expect(harness.activity.events.first?.title == "Cannot read the diff of Login.swift")
        #expect(harness.activity.events.first?.outcome == .failure)
    }

    @Test func aBranchChangeReloadsTheBranchCommits() async throws {
        store.scope = .branch
        await store.refreshBranchCommits()
        harness.spies.changes.branchCommitsResult = .success([commit])

        harness.events.post(.branchesChanged)

        try await waitUntil { store.branchCommits == [commit] }
    }

    @Test func aProjectChangeClearsEverything() async {
        harness.spies.changes.commitFilesResult = .success([file])
        await store.loadFiles("a1b2c3")
        store.toggleRow("a1b2c3", hash: "a1b2c3")

        harness.events.post(.projectChanged)

        #expect(store.files.isEmpty)
        #expect(store.expandedRow == nil)
        #expect(store.hasLoadedBranch == false)
        #expect(store.hasLoadedReflog == false)
    }
}
