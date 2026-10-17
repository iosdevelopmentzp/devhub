import AppKit
import SwiftUI

struct FooterView: View {
    @Environment(\.panelActions) private var actions
    @Environment(OutputPanelState.self) private var output

    private var tabHint: String {
        "⌘1–\(min(FeatureRegistry.all.count, 9)) tabs"
    }

    var body: some View {
        HStack(spacing: 12) {
            FooterStatus()
            Spacer()
            Button {
                output.toggle()
            } label: {
                Label("Output", systemImage: output.isVisible ? "chevron.down" : "chevron.up")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("o", modifiers: [.command, .shift])
            .hint("Show or hide the command output (⇧⌘O)")
            Text(tabHint)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption)
            if actions.isPinned == false {
                ResizeGrip()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.base)
    }
}

#Preview {
    FooterView()
        .previewEnvironment()
}
