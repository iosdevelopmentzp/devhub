import Foundation

package struct TabConfig: Codable, Hashable, Sendable, Identifiable {
    package var id: String
    package var title: String
    package var icon: String? = nil
    package var searchPrompt: String? = nil
    package var inputs: [ActionInput]? = nil
    package var sections: [TabSection]? = nil

    package init(
        id: String,
        title: String,
        icon: String? = nil,
        searchPrompt: String? = nil,
        inputs: [ActionInput]? = nil,
        sections: [TabSection]? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.searchPrompt = searchPrompt
        self.inputs = inputs
        self.sections = sections
    }

    package var actionIDs: [String] {
        (sections ?? []).flatMap { $0.actions ?? [] }
    }
}
