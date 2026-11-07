import Foundation
import DevHubDomain

enum NotificationKindText {

    static func title(for kind: NotificationKind, words: CodeHostWords) -> String {
        switch kind {
        case .build: "Builds"
        case .tests: "Test runs"
        case .reviewRequests: "\(words.requestsTitle) waiting for your review"
        case .reviewReminders: "Reviews waiting for me for too long"
        case .requestReviews: "Reviews of my \(words.requests)"
        case .requestChecks: "\(words.checksTitle) of my \(words.requests)"
        case .requestChecksPassed: "\(words.checksTitle) of my \(words.requests) passed"
        case .requestApprovals: "Jobs of my \(words.requests) waiting for approval"
        case .baseBranchChecks: "CI of the base branch"
        case .requestComments: "Comments on my \(words.requests)"
        case .requestClosed: "My \(words.requests) merged or closed"
        case .watched: "Watched \(words.requests)"
        case .inbox: "Inbox: mentions and requests on \(words.name)"
        case .crashes: "App crashes on a simulator"
        case .scripts: "Script notifications"
        case .utilities: "Utils: compressed videos"
        }
    }

    static func description(for kind: NotificationKind, words: CodeHostWords) -> String {
        switch kind {
        case .build: "A build or a launch finished, or the build failed. A click opens the run bar in the Simulators tab."
        case .tests: "The tests of a worktree finished or did not run. A click opens the Worktrees tab."
        case .reviewRequests: "The number of \(words.requests) that wait for your review went up. A click opens that list."
        case .reviewReminders: "A \(words.request) waits for your review longer than the time below. One reminder per \(words.request) until it leaves your queue. A click opens it."
        case .requestReviews: "Someone approved your \(words.request) or asked for changes. A click opens the \(words.request)."
        case .requestChecks: "The \(words.checks) of your \(words.request) turned to failed. A click opens the \(words.request)."
        case .requestChecksPassed: "The \(words.checks) of your \(words.request) passed after a run or a failure. A click opens the \(words.request)."
        case .requestApprovals: "A CircleCI job of your \(words.request) waits for an approval. A click opens the \(words.request), where the Approve button is."
        case .baseBranchChecks: "The latest CircleCI run of the base branch failed. A click opens the Git tab."
        case .requestComments: "Someone else commented on your \(words.request). Your own comments are silent. A click opens the \(words.request)."
        case .requestClosed: "Your \(words.request) was merged, or closed without a merge. A click opens the \(words.request)."
        case .watched: "A \(words.request) you watch got an approval, a request for changes, failed \(words.checks), a new comment, or was merged or closed. A click opens the \(words.request)."
        case .inbox: "Someone mentioned you, asked for your review or approval, assigned you, or commented where you take part, on \(words.name). A click opens the \(words.request) or the Inbox."
        case .crashes: "The app you launched from DevHub crashed on a simulator. DevHub reads the new crash report of macOS. A click opens the run bar with the report."
        case .scripts: "A script printed a notify line. It shows even while the panel is open and when the main switch is off."
        case .utilities: "A video finished compressing or could not be compressed. A click opens the Utils tab."
        }
    }

    static func shortTitle(for kind: NotificationKind, words: CodeHostWords) -> String {
        switch kind {
        case .build: "Build"
        case .tests: "Tests"
        case .reviewRequests, .reviewReminders: "Review"
        case .requestReviews, .requestChecks, .requestChecksPassed, .requestApprovals, .requestComments, .requestClosed: "My \(words.shortRequest)"
        case .baseBranchChecks: "CI"
        case .watched: "Watch"
        case .inbox: "Inbox"
        case .crashes: "Crash"
        case .scripts: "Script"
        case .utilities: "Utils"
        }
    }

    static func filterTitle(for filter: NotificationFilter, words: CodeHostWords) -> String {
        switch filter {
        case .all: "all events"
        case .kind(let kind): title(for: kind, words: words).lowercased()
        case .other: "other events"
        }
    }
}
