import Foundation
import DevHubDomain

struct ShellGitChangesRepository: GitChangesRepository {
    let git: GitCommandRunner

    private static let maxLines = 4000

    init(shell: ShellRunner) {
        git = GitCommandRunner(shell: shell)
    }

    func changes(in path: String) async throws -> [GitFileChange] {
        let output = try await git.run(["status", "--porcelain=v1", "-z", "--untracked-files=all"], in: path)
        return GitStatusParser.parse(output)
    }

    func diff(for change: GitFileChange, in path: String) async throws -> GitDiff {
        switch change.area {
        case .untracked:
            return untrackedDiff(at: (path as NSString).appendingPathComponent(change.path))
        case .staged:
            return cap(try await git.run(["diff", "--cached", "--no-color", "--", change.path], in: path))
        case .unstaged, .conflicted:
            return cap(try await git.run(["diff", "--no-color", "--", change.path], in: path))
        }
    }

    func branchCommits(base: String, remote: String, in path: String) async throws -> [GitCommit] {
        try await GitLogQuery(git: git).commits(range: "\(base)..HEAD", remote: remote, in: path)
    }

    func commitFiles(hash: String, in path: String) async throws -> [GitCommitFile] {
        let output = try await git.run(["show", "--first-parent", "--name-status", "-z", "--format=", hash], in: path)
        return GitCommitFilesParser.parse(output)
    }

    func commitDiff(hash: String, file: GitCommitFile, in path: String) async throws -> GitDiff {
        let paths = [file.originalPath, file.path].compactMap(\.self)
        return cap(try await git.run(["show", "--first-parent", "--no-color", "--format=", hash, "--"] + paths, in: path))
    }

    func stashFiles(hash: String, in path: String) async throws -> [GitCommitFile] {
        let tracked = GitCommitFilesParser.parse(try await git.run(["show", "--first-parent", "--name-status", "-z", "--format=", hash], in: path))
        let untrackedOutput = (try? await git.run(["show", "--name-status", "-z", "--format=", "\(hash)^3"], in: path)) ?? ""
        let untracked = GitCommitFilesParser.parse(untrackedOutput).map { GitCommitFile(path: $0.path, originalPath: nil, kind: .untracked) }
        return tracked + untracked
    }

    func stashDiff(hash: String, file: GitCommitFile, in path: String) async throws -> GitDiff {
        guard file.kind == .untracked else { return try await commitDiff(hash: hash, file: file, in: path) }
        return cap(try await git.run(["show", "--no-color", "--format=", "\(hash)^3", "--", file.path], in: path))
    }

    func branchesContaining(hash: String, in path: String) async throws -> [GitCommitRef] {
        let output = try await git.run(["branch", "-a", "--contains", hash, "--format=%(refname)"], in: path)
        return GitContainingBranchesParser.parse(output)
    }

    func reflog(in path: String) async throws -> [GitReflogEntry] {
        let output = try await git.run(["reflog", "-n", "200", "--date=unix", "--format=\(GitReflogParser.format)"], in: path)
        return GitReflogParser.parse(output)
    }

    func patch(_ scope: GitPatchScope, in path: String) async throws -> String {
        try await git.run(Self.patchArguments(scope), in: path)
    }

    func hiddenFiles(in path: String) async throws -> [GitHiddenFile] {
        let entries = GitHiddenFilesParser.entries(try await git.run(["ls-files", "-v", "-s", "-z"], in: path))
        let present = entries.filter { FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent($0.path)) }
        let hashes = present.isEmpty ? [] : try await git.run(["hash-object", "--"] + present.map(\.path), in: path).split(separator: "\n").map(String.init)
        let current = hashes.count == present.count ? Dictionary(uniqueKeysWithValues: zip(present.map(\.path), hashes)) : [:]
        return entries.map { entry in
            GitHiddenFile(path: entry.path, flags: entry.flags, state: Self.state(of: entry, current: current, isPresent: present.contains(entry)))
        }
    }

    func hiddenDiff(for file: GitHiddenFile, in path: String) async throws -> GitDiff {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("devhub-hidden-\(UUID().uuidString)").path
        defer { try? FileManager.default.removeItem(atPath: folder) }
        _ = try await git.run(Self.indexCopyArguments(file.path, into: folder), in: path)
        let copy = (folder as NSString).appendingPathComponent(file.path)
        let result = try await git.result(Self.hiddenDiffArguments(copy: copy, file: file), in: path)
        guard result.exitCode == 0 || result.exitCode == 1 else { throw WorktreeError.command(result.failureMessage) }
        return cap(result.stdout.replacingOccurrences(of: String(copy.dropFirst()), with: file.path))
    }

    static func indexCopyArguments(_ file: String, into folder: String) -> [String] {
        ["checkout-index", "--ignore-skip-worktree-bits", "--prefix=\(folder)/", "--", file]
    }

    static func hiddenDiffArguments(copy: String, file: GitHiddenFile) -> [String] {
        ["diff", "--no-index", "--no-color", "--no-ext-diff", "--", copy, file.state == .deleted ? "/dev/null" : file.path]
    }

    static func state(of entry: GitHiddenFilesParser.Entry, current: [String: String], isPresent: Bool) -> GitHiddenFile.State {
        guard isPresent else { return .deleted }
        return current[entry.path] == entry.objectID ? .unchanged : .modified
    }

    static func patchArguments(_ scope: GitPatchScope) -> [String] {
        switch scope {
        case .staged:
            ["diff", "--cached", "--no-color", "--no-ext-diff"]
        case let .range(base, head):
            ["diff", "--no-color", "--no-ext-diff", "\(base)...\(head)"]
        }
    }

    private func cap(_ output: String) -> GitDiff {
        GitDiffOutputParser.parse(output, maxLines: Self.maxLines)
    }

    private func untrackedDiff(at file: String) -> GitDiff {
        guard let data = FileManager.default.contents(atPath: file) else {
            return GitDiff(lines: [], droppedLines: 0, isBinary: false)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            return GitDiff(lines: [], droppedLines: 0, isBinary: true)
        }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { "+" + $0 }
        return GitDiff(lines: Array(lines.prefix(Self.maxLines)), droppedLines: max(lines.count - Self.maxLines, 0), isBinary: false)
    }
}
