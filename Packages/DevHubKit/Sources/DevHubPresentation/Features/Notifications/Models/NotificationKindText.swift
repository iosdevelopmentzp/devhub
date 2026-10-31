import Foundation
import DevHubDomain

enum NotificationKindText {

    static func title(for kind: NotificationKind, words: CodeHostWords) -> String {
        switch kind {
        case .build: "Builds"
        case .tests: "Test runs"
        case .reviewRequests: "\(words.requestsTitle) waiting for your review"
        case .requestReviews: "Reviews of my \(words.requests)"
        case .requestChecks: "\(words.checksTitle) of my \(words.requests)"
        case .requestComments: "Comments on my \(words.requests)"
        case .requestClosed: "My \(words.requests) merged or closed"
        case .scripts: "Script notifications"
        }
    }

    static func description(for kind: NotificationKind, words: CodeHostWords) -> String {
        switch kind {
        case .build: "A build or a launch finished, or the build failed. A click opens the run bar in the Simulators tab."
        case .tests: "The tests of a worktree finished or did not run. A click opens the Worktrees tab."
        case .reviewRequests: "The number of \(words.requests) that wait for your review went up. A click opens that list."
        case .requestReviews: "Someone approved your \(words.request) or asked for changes. A click opens the \(words.request)."
        case .requestChecks: "The \(words.checks) of your \(words.request) turned to failed. A click opens the \(words.request)."
        case .requestComments: "Someone else commented on your \(words.request). Your own comments are silent. A click opens the \(words.request)."
        case .requestClosed: "Your \(words.request) was merged, or closed without a merge. A click opens the \(words.request)."
        case .scripts: "A script printed a notify line. It shows even while the panel is open and when the main switch is off."
        }
    }

    static func shortTitle(for kind: NotificationKind, words: CodeHostWords) -> String {
        switch kind {
        case .build: "Build"
        case .tests: "Tests"
        case .reviewRequests: "Review"
        case .requestReviews, .requestChecks, .requestComments, .requestClosed: "My \(words.shortRequest)"
        case .scripts: "Script"
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
