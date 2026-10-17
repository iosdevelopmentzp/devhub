import SwiftUI
import DevHubDomain
import DevHubUI

struct LogsView: View {
    @Environment(LogsStore.self) private var logs
    @Environment(BuildStore.self) private var build
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(ProjectSession.self) private var session
    @Environment(\.panelOpenCount) private var openCount

    var body: some View {
        let lines = searchedLines
        return VStack(spacing: 0) {
            LogsToolbar(visibleLines: lines)
            Divider()
            content(lines: lines)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.surface)
        .task(id: openCount) {
            await logs.prepare(
                defaultUDID: LogTargetPolicy.defaultSimulator(target: build.target, simulators: simulators.all)?.id,
                knownUDIDs: Set(simulators.all.map(\.id))
            )
        }
    }

    private var searchedLines: [AppLogLine] {
        logs.visibleLines.filter { session.matchesSearch($0.message, $0.category) }
    }

    private func content(lines: [AppLogLine]) -> some View {
        ListState(
            failure: logs.isStreaming ? nil : logs.error.map { error in
                ListMessage.failure("Log stream stopped", description: error, actionTitle: "Start Again") {
                    logs.start()
                }
            },
            isLoading: false,
            loadingTitle: "",
            empty: logs.lines.isEmpty ? emptyMessage : nil,
            noResultsFor: nil
        ) {
            LogLinesList(
                rows: lines.map { LogLineRowMapper.model(for: $0) },
                followsTail: logs.isPaused == false
            )
        }
    }

    private var emptyMessage: ListMessage {
        ListMessage(
            logs.isStreaming ? "Waiting for log lines…" : "App logs",
            systemImage: "text.alignleft",
            description: logs.isStreaming
                ? "Use the app on the simulator. Lines from os_log and Logger appear here. print() output does not reach the system log."
                : "Pick a booted simulator and press Start. Tokens and passwords in the lines are masked. Nothing is saved to disk."
        )
    }
}

#Preview {
    LogsView()
        .previewEnvironment()
}
