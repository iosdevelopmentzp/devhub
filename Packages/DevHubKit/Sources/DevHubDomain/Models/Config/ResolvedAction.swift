import Foundation

package struct ResolvedAction: Identifiable, Hashable, Sendable {
    package var config: ActionConfig
    package var origin: ActionOrigin

    package var id: String {
        config.id
    }

    package init(
        config: ActionConfig,
        origin: ActionOrigin
    ) {
        self.config = config
        self.origin = origin
    }
}
