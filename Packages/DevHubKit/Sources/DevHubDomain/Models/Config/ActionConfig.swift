import Foundation

package struct ActionConfig: Codable, Hashable, Sendable {
    package var id: String
    package var title: String
    package var subtitle: String? = nil
    package var icon: String? = nil
    package var tint: ConfigTint? = nil
    package var placements: [Placement]? = nil
    package var run: ActionRun
    package var cwd: String? = nil
    package var inputs: [ActionInput]? = nil
    package var confirm: String? = nil
    package var refresh: [RefreshTarget]? = nil
    package var when: ActionCondition? = nil

    package var effectivePlacements: [Placement] {
        placements ?? [.homeScripts]
    }

    package func isPlaced(at placement: Placement) -> Bool {
        placement == .palette || effectivePlacements.contains(placement)
    }

    package init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        tint: ConfigTint? = nil,
        placements: [Placement]? = nil,
        run: ActionRun,
        cwd: String? = nil,
        inputs: [ActionInput]? = nil,
        confirm: String? = nil,
        refresh: [RefreshTarget]? = nil,
        when: ActionCondition? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.placements = placements
        self.run = run
        self.cwd = cwd
        self.inputs = inputs
        self.confirm = confirm
        self.refresh = refresh
        self.when = when
    }
}
