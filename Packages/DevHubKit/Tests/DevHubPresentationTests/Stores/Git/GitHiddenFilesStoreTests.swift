import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct GitHiddenFilesStoreTests {
    private let harness = StoreHarness()
    private let path = ProjectSample.path
    private let changed = GitHiddenFile(path: "Config/Local.xcconfig", flags: [.skipWorktree], state: .modified)
    private let same = GitHiddenFile(path: "Config/Environment.plist", flags: [.assumeUnchanged], state: .unchanged)

    private var store: GitHiddenFilesStore {
        harness.hiddenFiles
    }

    private var performed: [SpyGitRepository.Call] {
        harness.spies.git.calls.filter { if case .perform = $0 { true } else { false } }
    }

    private func load(_ files: [GitHiddenFile]) async {
        harness.spies.changes.hiddenFilesResult = .success(files)
        await store.refresh()
    }

    @Test func refreshLoadsTheHiddenFiles() async {
        await load([changed, same])

        #expect(store.files == [changed, same])
        #expect(store.changedCount == 1)
        #expect(store.loadedPath == path)
        #expect(store.error == nil)
        #expect(harness.spies.changes.calls == [.hiddenFiles(path: path)])
    }

    @Test func aFailedReadIsShown() async {
        harness.spies.changes.hiddenFilesResult = .failure(TestError.scripted("boom"))

        await store.refresh()

        #expect(store.error != nil)
    }

    @Test func expandingAChangedFileReadsItsHiddenDiff() async throws {
        await load([changed, same])
        harness.spies.changes.hiddenDiffResult = .success(GitDiff(lines: ["+local"], droppedLines: 0, isBinary: false))

        store.toggleDiff(changed)
        store.toggleDiff(same)

        try await waitUntil { store.diffs[changed.id] != nil && store.diffs[same.id] != nil }
        #expect(store.diffs[changed.id]?.lines == ["+local"])
        #expect(harness.spies.changes.calls.contains(.hiddenDiff(same, path: path)) == false)
    }

    @Test func hidingAFileRunsUpdateIndex() async throws {
        store.hide(path: "Config/Local.xcconfig", flag: .skipWorktree)

        try await waitUntil { store.busyTitle == nil && performed.isEmpty == false }
        #expect(performed == [.perform(.hide(path: "Config/Local.xcconfig", flag: .skipWorktree), path: path)])
        #expect(harness.activityTitles.contains("Hide changes of Local.xcconfig from git"))
    }

    @Test func pickedFilesAreHiddenByTheirPathInTheCheckout() async throws {
        let inside = URL(fileURLWithPath: (path as NSString).appendingPathComponent("Config/a.plist"))
        let outside = URL(fileURLWithPath: "/elsewhere/b.plist")

        store.hide(filesAt: [inside, outside], flag: .assumeUnchanged)

        try await waitUntil { store.busyTitle == nil && performed.isEmpty == false }
        #expect(performed == [.perform(.hide(path: "Config/a.plist", flag: .assumeUnchanged), path: path)])
        #expect(harness.activityTitles.contains("Cannot hide 1 file"))
    }

    @Test func stashAndTrackClearsTheFlagsThenStashes() async throws {
        await load([changed])

        store.track(changed, mode: .stashChanges)

        try await waitUntil { store.busyTitle == nil && performed.count == 2 }
        #expect(performed == [
            .perform(.unhide(path: "Config/Local.xcconfig"), path: path),
            .perform(.stashPath(path: "Config/Local.xcconfig", message: "Hidden changes of Config/Local.xcconfig"), path: path),
        ])
        #expect(harness.activityTitles.contains("Stash Local.xcconfig and track it again"))
    }

    @Test func projectChangedClearsTheList() async {
        await load([changed])

        harness.events.post(.projectChanged)

        #expect(store.files.isEmpty)
        #expect(store.loadedPath == nil)
    }
}
