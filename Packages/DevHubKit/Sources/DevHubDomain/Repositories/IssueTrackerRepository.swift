import Foundation

package protocol IssueTrackerRepository: Sendable {
    func toolState() async -> TrackerToolState
    func issues(jql: String, project: String?, order: IssueOrder, limit: Int) async throws -> [TrackerIssue]
    func issue(key: String) async throws -> TrackerIssue
    func details(key: String) async throws -> TrackerIssueDetails
    func transition(key: String, to status: String) async throws
    func assign(key: String, to user: String) async throws
    func unassign(key: String) async throws
    func watch(key: String, user: String) async throws
    func comment(key: String, text: String) async throws
}
