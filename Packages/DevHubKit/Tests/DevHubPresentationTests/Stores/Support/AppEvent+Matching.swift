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
        case .buildFinished(let id, let launch):
            "buildFinished(\(id), \(Self.describe(launch)))"
        case .appLaunched(let id, let launch):
            "appLaunched(\(id), \(Self.describe(launch)))"
        case .appStateReported(let id, let report):
            "appStateReported(\(id), \(report?.identity ?? "-"))"
        case .worktreeCheckoutPrepared:
            "worktreeCheckoutPrepared"
        case .worktreeBootstrapping(let path, let isRunning):
            "worktreeBootstrapping(\(path), \(isRunning))"
        case .mockSetChanged(let id):
            "mockSetChanged(\(id))"
        case .pullRequestsChanged:
            "pullRequestsChanged"
        case .pullRequestChecksChanged(let iid):
            "pullRequestChecksChanged(\(iid))"
        case .configChanged:
            "configChanged"
        case .refreshRequested(let target):
            "refreshRequested(\(target.rawValue))"
        }
    }

    private static func describe(_ launch: LaunchRecord?) -> String {
        guard let launch else { return "none" }
        return "\(launch.profileID ?? "-") \(launch.identity ?? "-")"
    }
}
