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
            updatedAt: Date(timeIntervalSinceNow: -3_600),
            labels: ["ios", "login"],
            dueDate: Date(timeIntervalSinceNow: 3 * 86_400)
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
            updatedAt: Date(timeIntervalSinceNow: -2 * 86_400),
            labels: ["ios", "crash", "offline"],
            dueDate: Date(timeIntervalSinceNow: -2 * 86_400)
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
            updatedAt: Date(timeIntervalSinceNow: -5 * 86_400),
            labels: ["onboarding"]
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
        TrackerIssue(
            key: "ABC-110",
            summary: "Show the order number on the receipt screen",
            status: "Done",
            statusCategory: .done,
            type: "Story",
            priority: "Medium",
            assignee: "Alex",
            url: URL(string: "https://jira.example.com/browse/ABC-110"),
            updatedAt: Date(timeIntervalSinceNow: -3 * 86_400)
        ),
    ]

    package static func issueDetails(key: String) -> TrackerIssueDetails {
        TrackerIssueDetails(
            key: key,
            description: "Steps:\n1. Open the login screen without a network connection.\n2. Tap Log In.\n3. Turn the network on and tap again.\n\nThe button stays disabled until the app restarts. Expected: it is enabled again after the failed request.",
            reporter: "Sam",
            createdAt: Date(timeIntervalSinceNow: -6 * 86_400),
            labels: ["ios", "login"],
            components: ["Auth"],
            parent: TrackerIssueLink(key: "ABC-100", summary: "Login flow rework", status: "In Progress", statusCategory: .inProgress),
            subtasks: [
                TrackerIssueLink(key: "ABC-131", summary: "Add a unit test for the retry", status: "To Do", statusCategory: .toDo),
            ],
            comments: [
                TrackerComment(id: "1", author: "Sam", body: "Happens on iOS 18 too. The request fails with a timeout.", createdAt: Date(timeIntervalSinceNow: -2 * 86_400)),
                TrackerComment(id: "2", author: "Alex", body: "Found it: the state is not reset after the error. Fix is on the way.", createdAt: Date(timeIntervalSinceNow: -3_600)),
            ],
            fixVersions: ["2.4.0"],
            dueDate: Date(timeIntervalSinceNow: 3 * 86_400),
            links: [
                TrackerIssueRelation(
                    relation: "blocks",
                    issue: TrackerIssueLink(key: "ABC-140", summary: "Release 2.4.0 checklist", status: "To Do", statusCategory: .toDo)
                ),
                TrackerIssueRelation(
                    relation: "is blocked by",
                    issue: TrackerIssueLink(key: "ABC-99", summary: "Session refresh endpoint", status: "Done", statusCategory: .done)
                ),
            ],
            attachments: ["login-screen.png", "console.log"],
            originalEstimateSeconds: 14_400,
            timeSpentSeconds: 5_400,
            remainingEstimateSeconds: 9_000,
            watchers: 3,
            isWatching: false
        )
    }
}
