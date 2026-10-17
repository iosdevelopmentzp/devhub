import SwiftUI

struct PanelActions {
    var isPinned = false
    var togglePin: () -> Void = {}
    var handleEscape: () -> Void = {}
    var resetPosition: () -> Void = {}
}

extension EnvironmentValues {
    @Entry var panelActions = PanelActions()
}
