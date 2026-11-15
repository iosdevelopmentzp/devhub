import DevHubDomain
import Foundation

package final class SpyIssueTrackerRepository: IssueTrackerRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case toolState
        case issues(jql: String, project: String?, order: IssueOrder, limit: Int)
        case issue(key: String)
        case details(key: String)
        case transition(key: String, status: String)
        case assign(key: String, user: String)
        case comment(key: String, text: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _toolStateResult: TrackerToolState = .ready(version: "1.7.0", user: "alex@example.com")
    private var _issuesResult: Result<[TrackerIssue], any Error> = .success([])
    private var _issueResult: Result<TrackerIssue, any Error> = .failure(TrackerError.command("No issue"))
    private var _detailsResult: Result<TrackerIssueDetails, any Error> = .failure(TrackerError.command("No issue"))
    private var _transitionError: (any Error)? = nil
    private var _assignError: (any Error)? = nil
    private var _commentError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var toolStateResult: TrackerToolState {
        get { lock.withLock { _toolStateResult } }
        set { lock.withLock { _toolStateResult = newValue } }
    }

    package var issuesResult: Result<[TrackerIssue], any Error> {
        get { lock.withLock { _issuesResult } }
        set { lock.withLock { _issuesResult = newValue } }
    }

    package var issueResult: Result<TrackerIssue, any Error> {
        get { lock.withLock { _issueResult } }
        set { lock.withLock { _issueResult = newValue } }
    }

    package var detailsResult: Result<TrackerIssueDetails, any Error> {
        get { lock.withLock { _detailsResult } }
        set { lock.withLock { _detailsResult = newValue } }
    }

    package var transitionError: (any Error)? {
        get { lock.withLock { _transitionError } }
        set { lock.withLock { _transitionError = newValue } }
    }

    package var assignError: (any Error)? {
        get { lock.withLock { _assignError } }
        set { lock.withLock { _assignError = newValue } }
    }

    package var commentError: (any Error)? {
        get { lock.withLock { _commentError } }
        set { lock.withLock { _commentError = newValue } }
    }

    package func toolState() async -> TrackerToolState {
        lock.withLock {
            _calls.append(.toolState)
            return _toolStateResult
        }
    }

    package func issues(jql: String, project: String?, order: IssueOrder, limit: Int) async throws -> [TrackerIssue] {
        try lock.withLock {
            _calls.append(.issues(jql: jql, project: project, order: order, limit: limit))
            return try _issuesResult.get()
        }
    }

    package func issue(key: String) async throws -> TrackerIssue {
        try lock.withLock {
            _calls.append(.issue(key: key))
            return try _issueResult.get()
        }
    }

    package func details(key: String) async throws -> TrackerIssueDetails {
        try lock.withLock {
            _calls.append(.details(key: key))
            return try _detailsResult.get()
        }
    }

    package func transition(key: String, to status: String) async throws {
        try lock.withLock {
            _calls.append(.transition(key: key, status: status))
            if let error = _transitionError { throw error }
        }
    }

    package func assign(key: String, to user: String) async throws {
        try lock.withLock {
            _calls.append(.assign(key: key, user: user))
            if let error = _assignError { throw error }
        }
    }

    package func comment(key: String, text: String) async throws {
        try lock.withLock {
            _calls.append(.comment(key: key, text: text))
            if let error = _commentError { throw error }
        }
    }
}
