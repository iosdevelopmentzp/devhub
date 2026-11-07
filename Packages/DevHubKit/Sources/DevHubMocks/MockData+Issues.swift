import Foundation
import DevHubDomain

extension MockData {
    package static let issues = [
        TrackerIssue(
            key: "ABC-123",
            summary: "Login button stays disabled after a failed request",
            status: "In Progress",
            statusCategory: .inProgress,
            type: "Bug",
            priority: "High",
            assignee: "Alex",
            url: URL(string: "https://jira.example.com/browse/ABC-123"),
            updatedAt: Date(timeIntervalSinceNow: -3_600)
        ),
        TrackerIssue(
            key: "ABC-130",
            summary: "Crash on launch without a network connection",
            status: "In Review",
            statusCategory: .inProgress,
            type: "Bug",
            priority: "Highest",
            assignee: "Alex",
            url: URL(string: "https://jira.example.com/browse/ABC-130"),
            updatedAt: Date(timeIntervalSinceNow: -2 * 86_400)
        ),
        TrackerIssue(
            key: "ABC-124",
            summary: "Onboarding: new welcome screen",
            status: "To Do",
            statusCategory: .toDo,
            type: "Story",
            priority: "Medium",
            assignee: "Alex",
            url: URL(string: "https://jira.example.com/browse/ABC-124"),
            updatedAt: Date(timeIntervalSinceNow: -5 * 86_400)
        ),
        TrackerIssue(
            key: "ABC-118",
            summary: "Rename the settings tab",
            status: "To Do",
            statusCategory: .toDo,
            type: "Task",
            priority: "Low",
            assignee: "Sam",
            url: URL(string: "https://jira.example.com/browse/ABC-118"),
            updatedAt: Date(timeIntervalSinceNow: -9 * 86_400)
        ),
    ]
}
