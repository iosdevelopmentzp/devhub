import SwiftUI
import DevHubDomain
import DevHubUI

struct ClaudeSessionsToolbar: View {
    @Environment(ClaudeSessionsStore.self) private var claude

    let count: Int

    var body: some View {
        @Bindable var claude = claude
        ToolbarBar(controlSize: .regular) {
            HStack(spacing: 8) {
                Text(CountText.invariant(count, "sessions"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                if claude.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
                Picker("Scope", selection: $claude.scope) {
                    ForEach(ClaudeSessionsStore.Scope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .hint("This project: sessions started inside the selected project or its worktrees. All: every Claude Code session.")
                IconButton(systemImage: "arrow.clockwise", help: "Read the sessions again") {
                    Task { await claude.refresh() }
                }
            }
        }
    }
}
