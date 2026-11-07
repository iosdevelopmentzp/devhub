import Foundation
import DevHubDomain

enum TodayTarget: Equatable {
    case pullRequests(PullRequestScope)
    case pullRequest(Int)
    case worktrees
    case simulators
    case git
}
