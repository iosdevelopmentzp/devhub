import Foundation
import DevHubDomain
import DevHubTestSupport

enum ConfigSample {
    static let directory = ProjectSample.path + "/.devhub"

    static func action(
        _ id: String,
        run: ActionRun = .script("scripts/run.sh"),
        placements: [Placement]? = nil,
        inputs: [ActionInput]? = nil,
        confirm: String? = nil,
        refresh: [RefreshTarget]? = nil,
        when: ActionCondition? = nil,
        isExecutable: Bool = true
    ) -> ResolvedAction {
        ResolvedAction(
            config: ActionConfig(id: id, title: id.capitalized, placements: placements, run: run, inputs: inputs, confirm: confirm, refresh: refresh, when: when),
            origin: ActionOrigin(layer: .project, directory: directory, fileName: "actions/\(id).json", isHeaderScript: false, isExecutable: isExecutable)
        )
    }

    static func resolved(_ actions: [ResolvedAction], issues: [ConfigIssue] = []) -> ResolvedConfig {
        ResolvedConfig(project: .empty, actions: actions, tabs: [], issues: issues, layers: [ConfigLayerInfo(layer: .project, directory: directory, exists: true)])
    }
}
