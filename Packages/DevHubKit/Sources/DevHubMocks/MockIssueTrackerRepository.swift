import Foundation
import DevHubDomain

struct MockIssueTrackerRepository: IssueTrackerRepository {
    func toolState() async -> TrackerToolState {
        .ready(version: "1.7.0", user: "alex@example.com")
    }

    func issues(jql: String, project: String?, order: IssueOrder, limit: Int) async throws -> [TrackerIssue] {
        try await Task.sleep(for: .milliseconds(150))
        if jql.contains("issuekey in (") {
            return MockData.issues.filter { jql.contains($0.key) }
        }
        let open = jql.contains("updated >=") ? MockData.issues : MockData.issues.filter { $0.statusCategory != .done }
        if jql.contains("issuekey in issueHistory()") {
            let recent = MockData.issues.prefix(3).map(\.key)
            return open.filter { recent.contains($0.key) }
        }
        if jql.contains("assignee = currentUser()") {
            return open.filter { $0.assignee == "Alex" }
        }
        if jql.contains("reporter = currentUser()") || jql.contains("watcher = currentUser()") {
            return open.filter { $0.assignee != "Alex" }
        }
        return open
    }

    func issue(key: String) async throws -> TrackerIssue {
        guard let issue = MockData.issues.first(where: { $0.key == key }) else {
            throw TrackerError.command("Issue does not exist or you do not have permission to see it.")
        }
        return issue
    }

    func details(key: String) async throws -> TrackerIssueDetails {
        try await Task.sleep(for: .milliseconds(200))
        guard MockData.issues.contains(where: { $0.key == key }) else {
            throw TrackerError.command("Issue does not exist or you do not have permission to see it.")
        }
        return MockData.issueDetails(key: key)
    }

    func transition(key: String, to status: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func assign(key: String, to user: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func unassign(key: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func watch(key: String, user: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func comment(key: String, text: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }
}
