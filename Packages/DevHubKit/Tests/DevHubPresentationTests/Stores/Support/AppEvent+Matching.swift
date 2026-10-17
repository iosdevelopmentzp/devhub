import DevHubDomain
@testable import DevHubPresentation

extension AppEvent {
    var label: String {
        switch self {
        case .projectChanged:
            "projectChanged"
        case .branchesChanged:
            "branchesChanged"
        case .worktreesChanged:
            "worktreesChanged"
        case .simulatorsChanged:
            "simulatorsChanged"
        case .commandFailed:
            "commandFailed"
        case .buildStarted(let id):
            "buildStarted(\(id))"
        case .buildFinished(let id, let launchedDeviceID):
            "buildFinished(\(id), \(Self.describe(launchedDeviceID)))"
        case .appLaunched(let id):
            "appLaunched(\(id))"
        case .worktreeCheckoutPrepared:
            "worktreeCheckoutPrepared"
        case .worktreeBootstrapping(let path, let isRunning):
            "worktreeBootstrapping(\(path), \(isRunning))"
        case .mockSetChanged(let id):
            "mockSetChanged(\(id))"
        case .mergeRequestsChanged:
            "mergeRequestsChanged"
        case .configChanged:
            "configChanged"
        case .refreshRequested(let target):
            "refreshRequested(\(target.rawValue))"
        }
    }

    private static func describe(_ launchedDeviceID: String??) -> String {
        switch launchedDeviceID {
        case .none:
            "none"
        case .some(.none):
            "nil"
        case .some(.some(let id)):
            id
        }
    }
}
