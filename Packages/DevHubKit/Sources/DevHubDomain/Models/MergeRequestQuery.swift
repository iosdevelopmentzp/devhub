import Foundation

package struct MergeRequestQuery: Hashable, Sendable {
    package var scope: MergeRequestScope
    package var state: MergeRequestStateFilter

    package init(scope: MergeRequestScope, state: MergeRequestStateFilter) {
        self.scope = scope
        self.state = state
    }
}
