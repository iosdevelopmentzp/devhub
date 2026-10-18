import Foundation
import DevHubDomain
import DevHubUI

enum AppEvent {
    case projectChanged
    case branchesChanged
    case worktreesChanged
    case simulatorsChanged
    case commandFailed
    case buildStarted(simulatorID: String)
    case buildFinished(simulatorID: String, launch: LaunchRecord?)
    case appLaunched(simulatorID: String, launch: LaunchRecord?)
    case appStateReported(simulatorID: String, report: AppStateReport?)
    case worktreeCheckoutPrepared
    case worktreeBootstrapping(path: String, isRunning: Bool)
    case mockSetChanged(id: MockSet.ID)
    case pullRequestsChanged
    case configChanged
    case refreshRequested(RefreshTarget)
}
