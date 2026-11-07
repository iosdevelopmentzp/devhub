import DevHubDomain
import Foundation

package final class SpyTestRunRepository: TestRunRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case run(TestRunRequest)
        case results(bundlePath: String, projectPath: String)
        case exportAttachments(bundlePath: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _runEvents: [TestEvent] = []
    private var _runResult: Result<TestRunReport, any Error> = .success(TestRunReport(status: .passed, resultBundlePath: nil))
    private var _runDelay: Duration = .zero
    private var _resultsResult: Result<[TestResultCase], any Error> = .success([])
    private var _attachmentsResult: Result<[TestAttachment], any Error> = .success([])

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var runEvents: [TestEvent] {
        get { lock.withLock { _runEvents } }
        set { lock.withLock { _runEvents = newValue } }
    }

    package var runResult: Result<TestRunReport, any Error> {
        get { lock.withLock { _runResult } }
        set { lock.withLock { _runResult = newValue } }
    }

    package var runDelay: Duration {
        get { lock.withLock { _runDelay } }
        set { lock.withLock { _runDelay = newValue } }
    }

    package var resultsResult: Result<[TestResultCase], any Error> {
        get { lock.withLock { _resultsResult } }
        set { lock.withLock { _resultsResult = newValue } }
    }

    package var attachmentsResult: Result<[TestAttachment], any Error> {
        get { lock.withLock { _attachmentsResult } }
        set { lock.withLock { _attachmentsResult = newValue } }
    }

    package func results(bundlePath: String, projectPath: String) async throws -> [TestResultCase] {
        let result = lock.withLock {
            _calls.append(.results(bundlePath: bundlePath, projectPath: projectPath))
            return _resultsResult
        }
        return try result.get()
    }

    package func exportAttachments(bundlePath: String) async throws -> [TestAttachment] {
        let result = lock.withLock {
            _calls.append(.exportAttachments(bundlePath: bundlePath))
            return _attachmentsResult
        }
        return try result.get()
    }

    package func run(_ request: TestRunRequest, onEvent: @escaping @Sendable (TestEvent) -> Void) async throws -> TestRunReport {
        let (events, result, delay) = lock.withLock {
            _calls.append(.run(request))
            return (_runEvents, _runResult, _runDelay)
        }
        events.forEach(onEvent)
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        return try result.get()
    }
}
