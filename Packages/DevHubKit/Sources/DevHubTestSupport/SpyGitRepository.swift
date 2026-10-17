import DevHubDomain
import Foundation

package final class SpyGitRepository: GitRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case state(checkoutPath: String, mainPath: String)
        case perform(GitCommand, path: String)
        case webURL(checkoutPath: String)
        case commitSubjects(base: String, head: String, path: String)
        case mergeRequestTemplate(path: String)
    }

    private static let emptyState = GitRepositoryState(
        snapshot: GitSnapshot(
            branch: nil,
            head: "",
            upstream: nil,
            ahead: 0,
            behind: 0,
            changedFiles: 0,
            stashCount: 0,
            operation: nil,
            baseBranch: "",
            aheadOfBase: 0,
            behindBase: 0,
            lastFetch: nil,
            webURL: nil
        ),
        localBranches: [],
        remoteBranches: [],
        history: []
    )

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _stateResult: Result<GitRepositoryState, any Error> = .success(SpyGitRepository.emptyState)
    private var _performError: (any Error)? = nil
    private var _commandErrors: [GitCommand: any Error] = [:]
    private var _webURLResult: URL? = nil
    private var _subjectsResult: [String] = []
    private var _templateResult: String? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var stateResult: Result<GitRepositoryState, any Error> {
        get { lock.withLock { _stateResult } }
        set { lock.withLock { _stateResult = newValue } }
    }

    package var performError: (any Error)? {
        get { lock.withLock { _performError } }
        set { lock.withLock { _performError = newValue } }
    }

    package var commandErrors: [GitCommand: any Error] {
        get { lock.withLock { _commandErrors } }
        set { lock.withLock { _commandErrors = newValue } }
    }

    package var subjectsResult: [String] {
        get { lock.withLock { _subjectsResult } }
        set { lock.withLock { _subjectsResult = newValue } }
    }

    package var templateResult: String? {
        get { lock.withLock { _templateResult } }
        set { lock.withLock { _templateResult = newValue } }
    }

    package func commitSubjects(from base: String, to head: String, in path: String) async throws -> [String] {
        record(.commitSubjects(base: base, head: head, path: path)) { _subjectsResult }
    }

    package func mergeRequestTemplate(in path: String) async -> String? {
        record(.mergeRequestTemplate(path: path)) { _templateResult }
    }

    package var webURLResult: URL? {
        get { lock.withLock { _webURLResult } }
        set { lock.withLock { _webURLResult = newValue } }
    }

    package func state(checkoutPath: String, mainPath: String) async throws -> GitRepositoryState {
        try record(.state(checkoutPath: checkoutPath, mainPath: mainPath)) { try _stateResult.get() }
    }

    package func perform(_ command: GitCommand, in path: String) async throws {
        let error = record(.perform(command, path: path)) { _commandErrors[command] ?? _performError }
        if let error { throw error }
    }

    package func webURL(checkoutPath: String) async -> URL? {
        record(.webURL(checkoutPath: checkoutPath)) { _webURLResult }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
