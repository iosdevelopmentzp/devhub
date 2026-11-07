import DevHubDomain
import Foundation

package final class SpyGitChangesRepository: GitChangesRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case changes(path: String)
        case diff(GitFileChange, path: String)
        case branchCommits(base: String, path: String)
        case commitFiles(hash: String, path: String)
        case commitDiff(hash: String, file: GitCommitFile, path: String)
        case stashFiles(hash: String, path: String)
        case stashDiff(hash: String, file: GitCommitFile, path: String)
        case branchesContaining(hash: String, path: String)
        case reflog(path: String)
        case patch(GitPatchScope, path: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _changesResult: Result<[GitFileChange], any Error> = .success([])
    private var _diffResult: Result<GitDiff, any Error> = .success(GitDiff(lines: [], droppedLines: 0, isBinary: false))
    private var _branchCommitsResult: Result<[GitCommit], any Error> = .success([])
    private var _commitFilesResult: Result<[GitCommitFile], any Error> = .success([])
    private var _reflogResult: Result<[GitReflogEntry], any Error> = .success([])
    private var _commitDiffResult: Result<GitDiff, any Error> = .success(GitDiff(lines: [], droppedLines: 0, isBinary: false))
    private var _patchResult: Result<String, any Error> = .success("")
    private var _stashFilesResult: Result<[GitCommitFile], any Error> = .success([])
    private var _stashDiffResult: Result<GitDiff, any Error> = .success(GitDiff(lines: [], droppedLines: 0, isBinary: false))
    private var _branchesContainingResult: Result<[GitCommitRef], any Error> = .success([])

    package init() {}

    package var patchResult: Result<String, any Error> {
        get { lock.withLock { _patchResult } }
        set { lock.withLock { _patchResult = newValue } }
    }

    package func patch(_ scope: GitPatchScope, in path: String) async throws -> String {
        try record(.patch(scope, path: path)) { try _patchResult.get() }
    }

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var changesResult: Result<[GitFileChange], any Error> {
        get { lock.withLock { _changesResult } }
        set { lock.withLock { _changesResult = newValue } }
    }

    package var diffResult: Result<GitDiff, any Error> {
        get { lock.withLock { _diffResult } }
        set { lock.withLock { _diffResult = newValue } }
    }

    package var branchCommitsResult: Result<[GitCommit], any Error> {
        get { lock.withLock { _branchCommitsResult } }
        set { lock.withLock { _branchCommitsResult = newValue } }
    }

    package var commitFilesResult: Result<[GitCommitFile], any Error> {
        get { lock.withLock { _commitFilesResult } }
        set { lock.withLock { _commitFilesResult = newValue } }
    }

    package var commitDiffResult: Result<GitDiff, any Error> {
        get { lock.withLock { _commitDiffResult } }
        set { lock.withLock { _commitDiffResult = newValue } }
    }

    package var reflogResult: Result<[GitReflogEntry], any Error> {
        get { lock.withLock { _reflogResult } }
        set { lock.withLock { _reflogResult = newValue } }
    }

    package func reflog(in path: String) async throws -> [GitReflogEntry] {
        try record(.reflog(path: path)) { try _reflogResult.get() }
    }

    package func changes(in path: String) async throws -> [GitFileChange] {
        try record(.changes(path: path)) { try _changesResult.get() }
    }

    package func diff(for change: GitFileChange, in path: String) async throws -> GitDiff {
        try record(.diff(change, path: path)) { try _diffResult.get() }
    }

    package func branchCommits(base: String, remote: String, in path: String) async throws -> [GitCommit] {
        try record(.branchCommits(base: base, path: path)) { try _branchCommitsResult.get() }
    }

    package func commitFiles(hash: String, in path: String) async throws -> [GitCommitFile] {
        try record(.commitFiles(hash: hash, path: path)) { try _commitFilesResult.get() }
    }

    package func commitDiff(hash: String, file: GitCommitFile, in path: String) async throws -> GitDiff {
        try record(.commitDiff(hash: hash, file: file, path: path)) { try _commitDiffResult.get() }
    }

    package var stashFilesResult: Result<[GitCommitFile], any Error> {
        get { lock.withLock { _stashFilesResult } }
        set { lock.withLock { _stashFilesResult = newValue } }
    }

    package var stashDiffResult: Result<GitDiff, any Error> {
        get { lock.withLock { _stashDiffResult } }
        set { lock.withLock { _stashDiffResult = newValue } }
    }

    package var branchesContainingResult: Result<[GitCommitRef], any Error> {
        get { lock.withLock { _branchesContainingResult } }
        set { lock.withLock { _branchesContainingResult = newValue } }
    }

    package func stashFiles(hash: String, in path: String) async throws -> [GitCommitFile] {
        try record(.stashFiles(hash: hash, path: path)) { try _stashFilesResult.get() }
    }

    package func stashDiff(hash: String, file: GitCommitFile, in path: String) async throws -> GitDiff {
        try record(.stashDiff(hash: hash, file: file, path: path)) { try _stashDiffResult.get() }
    }

    package func branchesContaining(hash: String, in path: String) async throws -> [GitCommitRef] {
        try record(.branchesContaining(hash: hash, path: path)) { try _branchesContainingResult.get() }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
