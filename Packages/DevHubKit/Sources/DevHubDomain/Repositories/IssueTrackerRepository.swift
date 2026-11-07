import Foundation

package protocol IssueTrackerRepository: Sendable {
    func toolState() async -> TrackerToolState
    func issues(jql: String, project: String?, limit: Int) async throws -> [TrackerIssue]
    func issue(key: String) async throws -> TrackerIssue
    func transition(key: String, to status: String) async throws
}
