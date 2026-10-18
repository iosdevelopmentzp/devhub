import SwiftUI
import DevHubDomain
import DevHubUI

struct LogsView: View {
    @Environment(LogsStore.self) private var logs
    @Environment(BuildStore.self) private var build
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(ProjectSession.self) private var session
    @Environment(\.panelOpenCount) private var openCount

    private static let printNote = "Lines from os_log and Logger appear here. print() output does not reach the system log."

    var body: some View {
        VStack(spacing: 0) {
            LogChipsBar()
            Divider()
            if let stream = logs.selected {
                let lines = searchedLines(stream)
                LogsToolbar(stream: stream, visibleLines: lines)
                Divider()
                content(stream, lines: lines)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ListState(failure: nil, isLoading: false, loadingTitle: "", empty: noStreamMessage, noResultsFor: nil) {
                    EmptyView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.surface)
        .task(id: openCount) {
            logs.prepare(defaultUDID: LogTargetPolicy.defaultSimulator(target: build.target, simulators: simulators.all)?.id)
        }
    }

    private func searchedLines(_ stream: LogStream) -> [AppLogLine] {
        stream.visibleLines.filter { session.matchesSearch($0.message, $0.category) }
    }

    private func content(_ stream: LogStream, lines: [AppLogLine]) -> some View {
        ListState(
            failure: stream.isRunning ? nil : stream.error.map { error in
                ListMessage.failure("Log stream stopped", description: error, actionTitle: "Start Again") {
                    logs.start(stream.id)
                }
            },
            isLoading: false,
            loadingTitle: "",
            empty: stream.lines.isEmpty ? emptyMessage(stream) : nil,
            noResultsFor: lines.isEmpty ? session.searchText : nil
        ) {
            LogLinesList(
                rows: lines.map { LogLineRowMapper.model(for: $0) },
                followsTail: stream.isPaused == false
            )
        }
    }

    private func emptyMessage(_ stream: LogStream) -> ListMessage {
        ListMessage(
            stream.isRunning ? "Waiting for log lines…" : "Stream is stopped",
            systemImage: "text.alignleft",
            description: stream.isRunning
                ? "Use the app on the simulator. \(Self.printNote)"
                : "Press Start. Tokens and passwords in the lines are masked. Nothing is saved to disk."
        )
    }

    private var noStreamMessage: ListMessage {
        ListMessage(
            "No log stream",
            systemImage: "text.alignleft",
            description: "Boot a simulator and press + to stream its logs. Each simulator gets its own stream. \(Self.printNote)"
        )
    }
}

#Preview {
    LogsView()
        .previewEnvironment()
}
