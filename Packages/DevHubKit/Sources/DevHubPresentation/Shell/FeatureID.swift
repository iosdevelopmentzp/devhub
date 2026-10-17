import DevHubDomain
import DevHubUI

enum FeatureID: String, CaseIterable, Hashable {
    case home
    case git
    case gitlab
    case worktrees
    case simulators
    case logs
    case network
    case claude
    case settings
}
