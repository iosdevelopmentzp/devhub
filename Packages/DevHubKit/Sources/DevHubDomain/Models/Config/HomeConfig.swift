import Foundation

package struct HomeConfig: Codable, Hashable, Sendable {
    package var quickActions: [String]? = nil

    package init(
        quickActions: [String]? = nil
    ) {
        self.quickActions = quickActions
    }
}
