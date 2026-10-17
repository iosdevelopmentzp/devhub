import SwiftUI

struct DragAreaBridge: View {
    @Environment(\.panelActions) private var actions
    @Environment(WindowLayout.self) private var layout

    var body: some View {
        WindowDragArea(
            onMoveEnd: { layout.savePanelTopLeft($0) },
            onDoubleClick: { actions.resetPosition() }
        )
    }
}
