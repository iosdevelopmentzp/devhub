import DevHubDomain

extension PullRequestScope {
    var title: String {
        switch self {
        case .mine: "Mine"
        case .reviewing: "To review"
        case .assigned: "Assigned"
        case .all: "All"
        }
    }
}
