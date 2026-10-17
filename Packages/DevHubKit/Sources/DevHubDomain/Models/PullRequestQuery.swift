import Foundation

package struct PullRequestQuery: Hashable, Sendable {
    package var scope: PullRequestScope
    package var state: PullRequestStateFilter

    package init(scope: PullRequestScope, state: PullRequestStateFilter) {
        self.scope = scope
        self.state = state
    }
}
