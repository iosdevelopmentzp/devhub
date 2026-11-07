import Foundation
import DevHubDomain

struct MockIssueTrackerRepository: IssueTrackerRepository {
    func toolState() async -> TrackerToolState {
        .ready(version: "1.7.0", user: "alex@example.com")
    }

    func issues(jql: String, project: String?, limit: Int) async throws -> [TrackerIssue] {
        try await Task.sleep(for: .milliseconds(150))
        return jql.contains("currentUser()") ? MockData.issues.filter { $0.assignee == "Alex" } : MockData.issues
    }

    func issue(key: String) async throws -> TrackerIssue {
        guard let issue = MockData.issues.first(where: { $0.key == key }) else {
            throw TrackerError.command("Issue does not exist or you do not have permission to see it.")
        }
        return issue
    }

    func transition(key: String, to status: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }
}
