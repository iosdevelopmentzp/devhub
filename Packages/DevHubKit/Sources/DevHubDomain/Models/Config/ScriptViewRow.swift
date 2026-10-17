import Foundation

package struct ScriptViewRow: Codable, Hashable, Sendable, Identifiable {
    package var id: String
    package var title: String
    package var subtitle: String? = nil
    package var tags: [ScriptViewTag]? = nil
    package var actions: [ScriptViewAction]? = nil

    package init(
        id: String,
        title: String,
        subtitle: String? = nil,
        tags: [ScriptViewTag]? = nil,
        actions: [ScriptViewAction]? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.tags = tags
        self.actions = actions
    }
}
