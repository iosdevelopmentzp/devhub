import SwiftUI
import DevHubDomain
import DevHubUI

struct PanelDragArea: View {
    @Environment(WindowLayout.self) private var layout
    @Environment(\.isPinnedWindow) private var isPinnedWindow

    var body: some View {
        WindowDragArea(
            onMoved: { window in
                guard isPinnedWindow == false else { return }
                layout.panelTopLeft = CGPoint(x: window.frame.minX, y: window.frame.maxY)
                layout.fit(window)
            },
            onDoubleClick: {
                guard isPinnedWindow == false else { return }
                layout.panelTopLeft = nil
            }
        )
    }
}
