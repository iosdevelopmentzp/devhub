import Foundation

nonisolated struct MockGitRepositoryProvider: GitRepositoryProviding {
    func summary(at path: String) async -> GitSummary {
        GitSummary(branch: "main", changeCount: 3, ahead: 1, behind: 0)
    }

    func remoteURL(at path: String) async -> String? {
        "git@github.com:example/app.git"
    }

    func status(at path: String) async throws -> GitStatus {
        GitStatus(
            branch: "feature/ABC-123-example",
            objectID: "0123456789abcdef0123456789abcdef01234567",
            upstream: "origin/feature/ABC-123-example",
            ahead: 1,
            behind: 0,
            changes: [
                GitChange(path: "Sources/App/Model.swift", originalPath: nil, index: "M", worktree: "."),
                GitChange(path: "Sources/App/View.swift", originalPath: nil, index: ".", worktree: "M"),
                GitChange(path: "Notes.md", originalPath: nil, index: "?", worktree: "?")
            ]
        )
    }

    func branches(at path: String, base: String) async throws -> BranchSnapshot {
        let now = Date()
        let local = [
            branch("feature/ABC-123-example", upstream: "origin/feature/ABC-123-example", ahead: 1, visit: now),
            branch("main", upstream: "origin/main", visit: now.addingTimeInterval(-3600)),
            branch("fix/local-only", upstream: nil, visit: now.addingTimeInterval(-7200)),
            branch("fix/finished", upstream: "origin/fix/finished", merged: true),
            branch("fix/gone", upstream: "origin/fix/gone", gone: true)
        ]
        let remote = [
            RemoteBranch(name: "feature/ABC-200-other", author: "Ada", date: now.addingTimeInterval(-900), subject: "Add other feature"),
            RemoteBranch(name: "main", author: "Grace", date: now.addingTimeInterval(-4000), subject: "Merge pull request")
        ]
        return BranchSnapshot(local: local, remote: remote)
    }

    func history(at path: String, limit: Int) async throws -> [GitCommit] {
        let now = Date()
        return [
            GitCommit(hash: "0123456789abcdef0123456789abcdef01234567", author: "Ada", date: now.addingTimeInterval(-600), subject: "ABC-123: Add the example", isPushed: false),
            GitCommit(hash: "89abcdef0123456789abcdef0123456789abcdef", author: "Grace", date: now.addingTimeInterval(-86400), subject: "Fix the layout", isPushed: true)
        ]
    }

    func details(at path: String, base: String) async -> CheckoutDetails {
        CheckoutDetails(operation: nil, lastFetch: Date().addingTimeInterval(-7200), stashCount: 2, distance: BranchDistance(ahead: 1, behind: 3))
    }

    func diff(at path: String, change: GitChange, group: GitChange.Group) async throws -> GitDiff {
        GitDiff(text: "@@ -1,2 +1,3 @@\n context\n-old line\n+new line\n+another line\n")
    }

    func run(_ command: GitCommand, at path: String) async throws -> ShellResult {
        ShellResult(stdout: "", stderr: "", exitCode: 0)
    }

    private func branch(_ name: String, upstream: String?, ahead: Int = 0, gone: Bool = false, merged: Bool = false, visit: Date? = nil) -> GitBranch {
        GitBranch(
            name: name,
            upstream: upstream,
            ahead: ahead,
            behind: 0,
            isUpstreamGone: gone,
            commitDate: Date().addingTimeInterval(-86400),
            worktreePath: nil,
            subject: "Sample commit",
            lastVisit: visit,
            isMerged: merged
        )
    }
}
