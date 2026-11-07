import DevHubDomain
import Foundation

package final class SpyUpdateRepository: UpdateRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case installed
        case check(commit: String)
        case start(commit: String)
        case status
        case isUpdateRunning
        case clearStatus
        case log
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _installedResult: Result<InstalledBuild?, any Error> = .success(nil)
    private var _checkResult: Result<UpdateCheck, any Error> = .success(.upToDate)
    private var _startError: (any Error)?
    private var _statusResults: [Result<UpdateStatus?, any Error>] = []
    private var _statusResult: Result<UpdateStatus?, any Error> = .success(nil)
    private var _isRunning = false
    private var _logResult: String?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var installedResult: Result<InstalledBuild?, any Error> {
        get { lock.withLock { _installedResult } }
        set { lock.withLock { _installedResult = newValue } }
    }

    package var checkResult: Result<UpdateCheck, any Error> {
        get { lock.withLock { _checkResult } }
        set { lock.withLock { _checkResult = newValue } }
    }

    package var startError: (any Error)? {
        get { lock.withLock { _startError } }
        set { lock.withLock { _startError = newValue } }
    }

    package var statusResult: Result<UpdateStatus?, any Error> {
        get { lock.withLock { _statusResult } }
        set { lock.withLock { _statusResult = newValue } }
    }

    package var statusResults: [Result<UpdateStatus?, any Error>] {
        get { lock.withLock { _statusResults } }
        set { lock.withLock { _statusResults = newValue } }
    }

    package var isRunning: Bool {
        get { lock.withLock { _isRunning } }
        set { lock.withLock { _isRunning = newValue } }
    }

    package var logResult: String? {
        get { lock.withLock { _logResult } }
        set { lock.withLock { _logResult = newValue } }
    }

    package func installed() async throws -> InstalledBuild? {
        try lock.withLock {
            _calls.append(.installed)
            return try _installedResult.get()
        }
    }

    package func check(installed: InstalledBuild) async throws -> UpdateCheck {
        try lock.withLock {
            _calls.append(.check(commit: installed.commit))
            return try _checkResult.get()
        }
    }

    package func start(installed: InstalledBuild) async throws {
        try lock.withLock {
            _calls.append(.start(commit: installed.commit))
            if let _startError { throw _startError }
        }
    }

    package func status() async throws -> UpdateStatus? {
        try lock.withLock {
            _calls.append(.status)
            if _statusResults.isEmpty == false {
                _statusResult = _statusResults.removeFirst()
            }
            return try _statusResult.get()
        }
    }

    package func isUpdateRunning() async -> Bool {
        lock.withLock {
            _calls.append(.isUpdateRunning)
            return _isRunning
        }
    }

    package func clearStatus() async throws {
        lock.withLock { _calls.append(.clearStatus) }
    }

    package func log() async throws -> String? {
        lock.withLock {
            _calls.append(.log)
            return _logResult
        }
    }
}
