import DevHubDomain

extension PullRequestStateFilter {
    var title: String {
        switch self {
        case .opened: "Open"
        case .merged: "Merged"
        case .closed: "Closed"
        case .all: "Any state"
        }
    }
}
