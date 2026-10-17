import Foundation

package struct ResolvedConfig: Hashable, Sendable {
    package var project: ProjectConfig
    package var actions: [ResolvedAction]
    package var tabs: [TabConfig]
    package var issues: [ConfigIssue]
    package var layers: [ConfigLayerInfo]

    package static let empty = ResolvedConfig(project: .empty, actions: [], tabs: [], issues: [], layers: [])

    package func action(id: String) -> ResolvedAction? {
        actions.first { $0.id == id }
    }

    package init(
        project: ProjectConfig,
        actions: [ResolvedAction],
        tabs: [TabConfig],
        issues: [ConfigIssue],
        layers: [ConfigLayerInfo]
    ) {
        self.project = project
        self.actions = actions
        self.tabs = tabs
        self.issues = issues
        self.layers = layers
    }
}
