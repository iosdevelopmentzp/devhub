import Foundation
import DevHubDomain

enum PullRequestsPreferenceKeys {
    static let scope = "gitlab.scope"
    static let state = "gitlab.state"
    static let filter = "gitlab.filter"
    static let listStyle = "gitlab.listStyle"
    static let listFraction = "gitlab.listFraction"

    static func seenAt(_ scope: PullRequestScope) -> String {
        "gitlab.seenAt.\(scope.rawValue)"
    }

    static func watched(projectID: String) -> String {
        "gitlab.watched.\(projectID)"
    }
}
