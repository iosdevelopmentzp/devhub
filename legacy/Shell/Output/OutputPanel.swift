import SwiftUI

struct OutputPanel: View {
    @Environment(CommandLog.self) private var commandLog
    @Environment(OutputPanelState.self) private var output

    private var entries: [CommandEntry] {
        output.visibleEntries(commandLog.entries)
    }

    var body: some View {
        VStack(spacing: 0) {
            OutputToolbar(entries: entries)
            Divider()
            if entries.isEmpty {
                EmptyState(
                    systemImage: "terminal",
                    title: emptyTitle,
                    text: emptyText
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { entry in
                            OutputEntryRow(entry: entry)
                            Divider()
                        }
                    }
                }
            }
        }
        .background(Theme.surface)
    }

    private var emptyTitle: String {
        output.searchText.isEmpty ? "No commands to show" : "No matching output"
    }

    private var emptyText: String {
        if output.searchText.isEmpty == false {
            return "No command, line or error matches the search."
        }
        return commandLog.entries.isEmpty ? "Commands the app runs will show here." : "Turn on Show reads to see read-only commands."
    }
}

#Preview {
    OutputPanel()
        .previewEnvironment()
}
