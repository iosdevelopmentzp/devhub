import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GitCommandEncoderTests {
    static let table: [(GitCommand, [String])] = [
        (.fetchPrune(remote: "origin"), ["fetch", "--prune", "origin"]),
        (.pullFastForward, ["pull", "--ff-only"]),
        (.push(branch: "feature", setUpstream: true, remote: "origin"), ["push", "-u", "origin", "feature"]),
        (.push(branch: "feature", setUpstream: false, remote: "origin"), ["push"]),
        (.forcePushWithLease(branch: "feature", remote: "origin"), ["push", "--force-with-lease", "-u", "origin", "feature"]),
        (.fetchBranch(source: "dev", local: "dev", remote: "origin"), ["fetch", "origin", "dev:dev"]),
        (.fetchRef("dev", remote: "origin"), ["fetch", "origin", "dev"]),
        (.rebase(onto: "origin/dev", autostash: true), ["rebase", "--autostash", "origin/dev"]),
        (.rebase(onto: "origin/dev", autostash: false), ["rebase", "origin/dev"]),
        (.continueRebase, ["rebase", "--continue"]),
        (.abort(operation: "merge"), ["merge", "--abort"]),
        (.stashPush(message: nil, includeUntracked: true), ["stash", "push", "--include-untracked"]),
        (.stashPush(message: nil, includeUntracked: false), ["stash", "push"]),
        (.stashPush(message: "  half done ", includeUntracked: true), ["stash", "push", "--include-untracked", "-m", "half done"]),
        (.stashPush(message: " ", includeUntracked: false), ["stash", "push"]),
        (.stashPop(index: nil), ["stash", "pop"]),
        (.stashPop(index: 3), ["stash", "pop", "stash@{3}"]),
        (.stashApply(index: 0), ["stash", "apply", "stash@{0}"]),
        (.stashDrop(index: 12), ["stash", "drop", "stash@{12}"]),
        (.switchBranch("main"), ["switch", "main"]),
        (.createTrackingBranch(local: "feature", remote: "origin/feature"), ["switch", "--track", "-c", "feature", "origin/feature"]),
        (.deleteBranch("old", force: false), ["branch", "-d", "old"]),
        (.deleteBranch("old", force: true), ["branch", "-D", "old"]),
        (.stage(path: "a b.swift"), ["add", "--", "a b.swift"]),
        (.unstage(path: "a.swift"), ["restore", "--staged", "--", "a.swift"]),
        (.restore(path: "a.swift"), ["restore", "--", "a.swift"]),
        (.restoreStagedAndWorktree(path: "a.swift"), ["restore", "--staged", "--worktree", "--", "a.swift"]),
        (.cleanUntracked(path: "new.txt"), ["clean", "-f", "--", "new.txt"]),
        (.stageAll, ["add", "-A"]),
        (.unstageAll, ["reset", "-q"]),
        (.commit(message: "ABC-1: Fix", amend: false), ["commit", "-m", "ABC-1: Fix"]),
        (.commit(message: "ABC-1: Fix", amend: true), ["commit", "-m", "ABC-1: Fix", "--amend"]),
    ]

    @Test(arguments: table)
    func arguments(command: GitCommand, expected: [String]) {
        #expect(GitCommandEncoder.arguments(for: command) == expected)
    }

    @Test(arguments: table.map(\.0))
    func environmentSetsEditorOnlyForContinueRebase(command: GitCommand) {
        let expected = command == .continueRebase ? ["GIT_EDITOR": "true"] : [:]
        #expect(GitCommandEncoder.environment(for: command) == expected)
    }

    @Test func theRemoteNameReachesEveryRemoteCommand() {
        #expect(GitCommandEncoder.arguments(for: .fetchPrune(remote: "upstream")) == ["fetch", "--prune", "upstream"])
        #expect(GitCommandEncoder.arguments(for: .push(branch: "x", setUpstream: true, remote: "upstream")) == ["push", "-u", "upstream", "x"])
        #expect(GitCommandEncoder.arguments(for: .forcePushWithLease(branch: "x", remote: "upstream")) == ["push", "--force-with-lease", "-u", "upstream", "x"])
        #expect(GitCommandEncoder.arguments(for: .fetchBranch(source: "a", local: "b", remote: "upstream")) == ["fetch", "upstream", "a:b"])
        #expect(GitCommandEncoder.arguments(for: .fetchRef("main", remote: "upstream")) == ["fetch", "upstream", "main"])
    }

    @Test func tableCoversEveryCase() {
        let names = Set(Self.table.map { String(describing: $0.0).prefix { $0 != "(" } })
        #expect(names.count == 24)
    }
}
