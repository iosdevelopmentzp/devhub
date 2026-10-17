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
    case buildFinished(simulatorID: String, launchedDeviceID: String??)
    case appLaunched(simulatorID: String)
    case worktreeCheckoutPrepared
    case worktreeBootstrapping(path: String, isRunning: Bool)
    case mockSetChanged(id: MockSet.ID)
    case mergeRequestsChanged
    case configChanged
    case refreshRequested(RefreshTarget)
}
