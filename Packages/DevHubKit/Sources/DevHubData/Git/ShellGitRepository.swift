import Foundation
import DevHubDomain

struct ShellGitRepository: GitRepository {
    let git: GitCommandRunner
    let mergedBranches: MergedBranchesQuery
    let worktrees: any WorktreeRepository

    private static let field = "%09"

    init(shell: ShellRunner, worktrees: any WorktreeRepository) {
        git = GitCommandRunner(shell: shell)
        mergedBranches = MergedBranchesQuery(git: git)
        self.worktrees = worktrees
    }

    func state(checkoutPath: String, mainPath: String, settings: GitSettings) async throws -> GitRepositoryState {
        let path = (checkoutPath as NSString).expandingTildeInPath
        let main = (mainPath as NSString).expandingTildeInPath
        let remote = settings.remote
        let detected = await worktrees.baseBranch(projectPath: main, remote: remote)
        let base = settings.baseBranch ?? detected

        async let snapshot = snapshot(in: path, base: base, remote: remote)
        async let locals = localBranches(in: path, main: main, base: base, remote: remote)
        async let remotes = remoteBranches(in: path, remote: remote)
        async let history = history(in: path, remote: remote)
        async let stashes = stashes(in: path)
        var state = try await GitRepositoryState(snapshot: snapshot, localBranches: locals, remoteBranches: remotes, history: history, stashes: stashes)
        state.snapshot.stashCount = state.stashes.count
        return state
    }

    func perform(_ command: GitCommand, in path: String) async throws {
        _ = try await git.run(
            GitCommandEncoder.arguments(for: command),
            in: path,
            environment: GitCommandEncoder.environment(for: command)
        )
    }

    // MARK: Snapshot

    private func snapshot(in path: String, base: String, remote: String) async throws -> GitSnapshot {
        let status = try await git.run(["status", "--porcelain=v2", "--branch"], in: path)
        var snapshot = GitBranchHeaderParser.parse(status, base: base)

        async let counts = try? git.run(["rev-list", "--left-right", "--count", "HEAD...\(base)"], in: path)
        async let operation = operation(in: path)
        async let commonDir = try? git.run(["rev-parse", "--git-common-dir"], in: path)
        async let remoteURL = try? git.run(["remote", "get-url", remote], in: path)

        let numbers = (await counts)?.split(whereSeparator: { $0 == "\t" || $0 == " " || $0 == "\n" }).compactMap { Int($0) } ?? []
        if numbers.count == 2 {
            snapshot.aheadOfBase = numbers[0]
            snapshot.behindBase = numbers[1]
        }
        snapshot.operation = await operation
        if let common = await commonDir?.trimmed {
            let directory = common.hasPrefix("/") ? common : (path as NSString).appendingPathComponent(common)
            let fetchHead = (directory as NSString).appendingPathComponent("FETCH_HEAD")
            snapshot.lastFetch = (try? FileManager.default.attributesOfItem(atPath: fetchHead))?[.modificationDate] as? Date
        }
        snapshot.webURL = (await remoteURL).flatMap { Self.webURL(fromRemote: $0.trimmed) }
        return snapshot
    }

    private func operation(in path: String) async -> String? {
        let markers: [(String, String)] = [("rebase-merge", "rebase"), ("rebase-apply", "rebase"), ("MERGE_HEAD", "merge"), ("CHERRY_PICK_HEAD", "cherry-pick")]
        for (marker, name) in markers {
            guard let output = try? await git.run(["rev-parse", "--git-path", marker], in: path) else { continue }
            let relative = output.trimmed
            let full = relative.hasPrefix("/") ? relative : (path as NSString).appendingPathComponent(relative)
            if FileManager.default.fileExists(atPath: full) { return name }
        }
        return nil
    }

    func webURL(checkoutPath: String, remote: String) async -> URL? {
        guard let url = try? await git.run(["remote", "get-url", remote], in: checkoutPath) else { return nil }
        return Self.webURL(fromRemote: url.trimmed)
    }

    func commitSubjects(from base: String, to head: String, in path: String) async throws -> [String] {
        let output = try await git.run(["log", "--format=%s", "-n", "50", "\(base)..\(head)"], in: path)
        return output.split(separator: "\n").map(String.init)
    }

    func pullRequestTemplate(in path: String, file: String) async -> String? {
        let full = ((path as NSString).expandingTildeInPath as NSString).appendingPathComponent(file)
        return try? String(contentsOfFile: full, encoding: .utf8)
    }

    static func webURL(fromRemote remote: String) -> URL? {
        var value = remote
        if value.hasSuffix(".git") { value.removeLast(4) }
        if value.hasPrefix("git@"), let colon = value.firstIndex(of: ":") {
            let host = value[value.index(value.startIndex, offsetBy: 4)..<colon]
            value = "https://\(host)/\(value[value.index(after: colon)...])"
        } else if value.hasPrefix("ssh://") {
            value = value.replacingOccurrences(of: "ssh://git@", with: "https://").replacingOccurrences(of: "ssh://", with: "https://")
        }
        return URL(string: value)
    }

    // MARK: Branches

    private func localBranches(in path: String, main: String, base: String, remote: String) async throws -> [GitBranch] {
        let format = ["%(refname:short)", "%(upstream:short)", "%(upstream:track,nobracket)", "%(committerdate:unix)", "%(worktreepath)", "%(authorname)", "%(contents:subject)"].joined(separator: Self.field)
        async let refs = git.run(["for-each-ref", "refs/heads", "--format=\(format)"], in: path)
        async let merged = mergedBranches.branches(mergedInto: base, in: path)
        async let visits = visitTimes(in: main)
        let mergedSet = await merged.subtracting([BranchName(base, remote: remote).local])
        let visitMap = await visits

        return try await LocalBranchParser.parse(refs, merged: mergedSet, visits: visitMap, remote: remote)
    }

    private func visitTimes(in path: String) async -> [String: Date] {
        guard let output = try? await git.run(["reflog", "show", "--format=%gs%x09%ct", "-n", "3000", "HEAD"], in: path) else { return [:] }
        return ReflogVisitParser.parse(output)
    }

    private func stashes(in path: String) async -> [GitStash] {
        let format = ["%gd", "%ct", "%gs"].joined(separator: "%x09")
        guard let output = try? await git.run(["stash", "list", "--format=\(format)"], in: path) else { return [] }
        return GitStashParser.parse(output)
    }

    private func remoteBranches(in path: String, remote: String) async throws -> [RemoteBranch] {
        let format = ["%(refname:short)", "%(committerdate:unix)", "%(authorname)", "%(contents:subject)"].joined(separator: Self.field)
        let output = try await git.run(["for-each-ref", "refs/remotes/\(remote)", "--sort=-committerdate", "--format=\(format)"], in: path)
        return RemoteBranchParser.parse(output, remote: remote)
    }

    private func history(in path: String, remote: String) async throws -> [GitCommit] {
        try await GitLogQuery(git: git).commits(range: nil, remote: remote, in: path)
    }
}
