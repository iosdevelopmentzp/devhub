import SwiftUI
import DevHubDomain
import DevHubUI

struct OutputToggle: View {
    @Environment(OutputPanelState.self) private var output
    @Environment(CommandLog.self) private var commandLog

    private var runningCount: Int {
        commandLog.entries.filter { $0.isRunning && $0.kind != .read }.count
    }

    private var hasRecentFailure: Bool {
        commandLog.entries.suffix(5).contains { $0.isFailure && $0.kind != .read }
    }

    var body: some View {
        Button {
            output.isVisible.toggle()
        } label: {
            HStack(spacing: 5) {
                if runningCount > 0 {
                    ProgressView()
                        .controlSize(.mini)
                } else if hasRecentFailure {
                    StatusDot(color: .red)
                }
                Image(systemName: output.isVisible ? "chevron.down" : "chevron.up")
                Text("Output")
            }
        }
        .controlSize(.small)
        .keyboardShortcut("o", modifiers: [.command, .shift])
        .hint("Show or hide the command output (⇧⌘O)")
    }
}
