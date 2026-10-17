import SwiftUI

struct LogsView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(LogsStore.self) private var store

    private static let printNote = "Only os_log and Logger lines reach the system log. print() output does not."

    private func visible(_ stream: LogStream) -> [LogLine] {
        stream.lines.filter { line in
            stream.level.includes(line.level) && session.matchesSearch(line.message, line.subsystem, line.category)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            LogChipsBar()
            Divider()
            if let stream = store.selected {
                streamContent(stream)
            } else {
                EmptyState(
                    systemImage: "text.alignleft",
                    title: "No log stream",
                    text: "Press + to stream the logs of a booted simulator. \(Self.printNote)"
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.surface)
        .task {
            while Task.isCancelled == false {
                await store.refreshSimulators()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    @ViewBuilder
    private func streamContent(_ stream: LogStream) -> some View {
        let lines = visible(stream)
        LogsToolbar(stream: stream, visible: lines)
        Divider()
        statusLine(stream, shown: lines.count)
        if let error = stream.error {
            InlineError(text: error) { store.start(stream.id) }
        }
        if stream.lines.isEmpty {
            EmptyState(
                systemImage: "text.alignleft",
                title: stream.isRunning ? "Waiting for log lines" : "Stream is stopped",
                text: stream.isRunning ? Self.printNote : "Press Start to stream. \(Self.printNote)"
            )
        } else if lines.isEmpty {
            ContentUnavailableView.search(text: session.searchText)
                .frame(maxHeight: .infinity)
        } else {
            LogLinesList(stream: stream, lines: lines)
        }
    }

    private func statusLine(_ stream: LogStream, shown: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(shown) of \(stream.lines.count) lines")
            if stream.dropped > 0 {
                Text("\(stream.dropped) dropped")
                    .foregroundStyle(Tint.orange.color)
            }
            if stream.isPaused {
                Text("Paused, \(stream.pending.count) waiting")
                    .foregroundStyle(Tint.blue.color)
            }
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }
}

#Preview {
    LogsView()
        .previewEnvironment()
}
