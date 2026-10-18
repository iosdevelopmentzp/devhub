import SwiftUI
import DevHubDomain
import DevHubUI

struct FooterView: View {
    @Environment(BuildStore.self) private var build
    @Environment(ConfigActionsStore.self) private var configActions
    @Environment(ConfigStore.self) private var config
    @Environment(\.isPinnedWindow) private var isPinnedWindow

    var body: some View {
        HStack(spacing: 10) {
            if let progress = configActions.progress, build.isRunning == false {
                ScriptProgressLabel(progress: progress)
            } else {
                BuildStatusLabel(phase: build.state.phase)
            }
            Spacer()
            OutputToggle()
            Text("⌘1–\(min(FeatureRegistry.tabBarFeatures.count + config.resolved.tabs.count, 9)) tabs")
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
