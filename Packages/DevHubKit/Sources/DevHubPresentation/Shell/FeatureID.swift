import DevHubDomain
import DevHubUI

enum FeatureID: String, CaseIterable, Hashable {
    case home
    case git
    case pullRequests
    case worktrees
    case simulators
    case logs
    case network
    case ai
    case notifications
    case settings
}
