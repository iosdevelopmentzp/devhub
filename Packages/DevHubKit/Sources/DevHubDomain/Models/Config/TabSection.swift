import Foundation

package struct TabSection: Codable, Hashable, Sendable {
    package var title: String
    package var actions: [String]? = nil
    package var source: TabSource? = nil

    package init(
        title: String,
        actions: [String]? = nil,
        source: TabSource? = nil
    ) {
        self.title = title
        self.actions = actions
        self.source = source
    }
}
