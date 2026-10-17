import SwiftUI
import DevHubDomain
import DevHubUI

struct FooterView: View {
    @Environment(BuildStore.self) private var build
    @Environment(\.isPinnedWindow) private var isPinnedWindow

    var body: some View {
        HStack(spacing: 10) {
            BuildStatusLabel(phase: build.state.phase)
            Spacer()
            OutputToggle()
            Text("⌘1–\(FeatureRegistry.tabBarFeatures.count) tabs")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .controlSize(.small)
            .keyboardShortcut("q")
            if isPinnedWindow == false {
                ResizeGrip()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(PanelDragArea())
    }
}
