import SwiftUI
import DevHubDomain
import DevHubUI

struct AISessionsToolbar: View {
    @Environment(AISessionsStore.self) private var sessions

    let count: Int

    var body: some View {
        @Bindable var sessions = sessions
        ToolbarBar(controlSize: .regular) {
            HStack(spacing: 8) {
                Text(CountText.invariant(count, "sessions"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                if sessions.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
                Picker("Provider", selection: $sessions.providerFilter) {
                    ForEach(AISessionsStore.ProviderFilter.allCases) { filter in
                        Text(AISessionsToolbar.title(for: filter)).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .hint("Show Copilot CLI sessions, Claude Code sessions or both")
                Picker("Scope", selection: $sessions.scope) {
                    ForEach(AISessionsStore.Scope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .hint("This project: sessions started inside the selected project or its worktrees. All: every session.")
                IconButton(systemImage: "arrow.clockwise", help: "Read the sessions again") {
                    Task { await sessions.refresh() }
                }
            }
        }
    }

    private static func title(for filter: AISessionsStore.ProviderFilter) -> String {
        switch filter {
        case .copilot: AISessionRowMapper.title(for: .copilot)
        case .claude: AISessionRowMapper.title(for: .claude)
        case .both: "Both"
        }
    }
}
