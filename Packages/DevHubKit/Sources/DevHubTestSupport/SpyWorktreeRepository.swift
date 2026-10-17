import DevHubDomain
import Foundation

package final class SpyWorktreeRepository: WorktreeRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case list(projectPath: String)
        case baseBranch(projectPath: String)
        case fetch(projectPath: String)
        case remove(Worktree, projectPath: String)
        case deleteBranch(String, projectPath: String)
        case prune(projectPath: String)
        case create(branch: String, base: String, projectPath: String)
        case bootstrap(worktreePath: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _settings: [GitSettings] = []
    private var _remotes: [String] = []
    private var _scripts: [String] = []
    private var _listResult: Result<[Worktree], any Error> = .success([])
    private var _baseBranchResult: String = "main"
    private var _fetchError: (any Error)? = nil
    private var _removeError: (any Error)? = nil
    private var _deleteBranchError: (any Error)? = nil
    private var _pruneError: (any Error)? = nil
    private var _createResult: Result<NewWorktree, any Error> = .success(NewWorktree(path: "", branch: ""))
    private var _bootstrapLines: [String] = []
    private var _bootstrapError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var settings: [GitSettings] {
        lock.withLock { _settings }
    }

    package var remotes: [String] {
        lock.withLock { _remotes }
    }

    package var scripts: [String] {
        lock.withLock { _scripts }
    }

    package var listResult: Result<[Worktree], any Error> {
        get { lock.withLock { _listResult } }
        set { lock.withLock { _listResult = newValue } }
    }

    package var baseBranchResult: String {
        get { lock.withLock { _baseBranchResult } }
        set { lock.withLock { _baseBranchResult = newValue } }
    }

    package var fetchError: (any Error)? {
        get { lock.withLock { _fetchError } }
        set { lock.withLock { _fetchError = newValue } }
    }

    package var removeError: (any Error)? {
        get { lock.withLock { _removeError } }
        set { lock.withLock { _removeError = newValue } }
    }

    package var deleteBranchError: (any Error)? {
        get { lock.withLock { _deleteBranchError } }
        set { lock.withLock { _deleteBranchError = newValue } }
    }

    package var pruneError: (any Error)? {
        get { lock.withLock { _pruneError } }
        set { lock.withLock { _pruneError = newValue } }
    }

    package var createResult: Result<NewWorktree, any Error> {
        get { lock.withLock { _createResult } }
        set { lock.withLock { _createResult = newValue } }
    }

    package var bootstrapLines: [String] {
        get { lock.withLock { _bootstrapLines } }
        set { lock.withLock { _bootstrapLines = newValue } }
    }

    package var bootstrapError: (any Error)? {
        get { lock.withLock { _bootstrapError } }
        set { lock.withLock { _bootstrapError = newValue } }
    }

    package func list(projectPath: String, settings: GitSettings) async throws -> [Worktree] {
        try record(.list(projectPath: projectPath)) {
            _settings.append(settings)
            return try _listResult.get()
        }
    }

    package func baseBranch(projectPath: String, remote: String) async -> String {
        record(.baseBranch(projectPath: projectPath)) {
            _remotes.append(remote)
            return _baseBranchResult
        }
    }

    package func fetch(projectPath: String, remote: String) async throws {
        let error = record(.fetch(projectPath: projectPath)) {
            _remotes.append(remote)
            return _fetchError
        }
        if let error { throw error }
    }

    package func remove(_ worktree: Worktree, projectPath: String) async throws {
        let error = record(.remove(worktree, projectPath: projectPath)) { _removeError }
        if let error { throw error }
    }

    package func deleteBranch(_ branch: String, projectPath: String) async throws {
        let error = record(.deleteBranch(branch, projectPath: projectPath)) { _deleteBranchError }
        if let error { throw error }
    }

    package func prune(projectPath: String) async throws {
        let error = record(.prune(projectPath: projectPath)) { _pruneError }
        if let error { throw error }
    }

    package func create(branch: String, base: String, projectPath: String, settings: GitSettings) async throws -> NewWorktree {
        try record(.create(branch: branch, base: base, projectPath: projectPath)) {
            _settings.append(settings)
            return try _createResult.get()
        }
    }

    package func bootstrap(worktreePath: String, script: String, onLine: @escaping @Sendable (String) -> Void) async throws {
        let (lines, error) = record(.bootstrap(worktreePath: worktreePath)) {
            _scripts.append(script)
            return (_bootstrapLines, _bootstrapError)
        }
        lines.forEach(onLine)
        if let error { throw error }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
