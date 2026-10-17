import SwiftUI
import DevHubDomain
import DevHubUI

struct OutputPanel: View {
    @Environment(OutputPanelState.self) private var output
    @Environment(CommandLog.self) private var commandLog
    @Environment(Toaster.self) private var toaster

    @State private var expandedIDs: Set<UUID> = []
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if entries.isEmpty {
                            Text("Commands DevHub runs appear here with their output.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(14)
                        }
                        ForEach(entries) { entry in
                            OutputEntryView(
                                model: OutputEntryMapper.model(for: entry, isExpanded: expandedIDs.contains(entry.id), now: .now),
                                onCopy: { toaster.copy(OutputEntryMapper.transcript(for: entry), label: "Command and output") },
                                onToggle: { toggle(entry.id) }
                            )
                            .id(entry.id)
                            Divider()
                        }
                    }
                }
                .onChange(of: entries.last?.id) { _, last in
                    guard let last else { return }
                    proxy.scrollTo(last, anchor: .bottom)
                }
                .onChange(of: entries.last?.lines.count) { _, _ in
                    guard let last = entries.last?.id else { return }
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
        .frame(height: 260)
        .background(Theme.surface)
    }

    private var entries: [CommandLog.Entry] {
        OutputEntryMapper.visibleEntries(commandLog.entries, showsReads: output.showsReads, query: query)
    }

    private var header: some View {
        @Bindable var output = output
        return ToolbarBar(verticalPadding: 6) {
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.secondary)
                Text("Output")
                    .font(.caption.weight(.semibold))
                Text(CountText.invariant(entries.count, "commands"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                SearchField(prompt: "Search output", text: $query, focus: nil)
                    .frame(maxWidth: 200)
                Toggle("Show reads", isOn: $output.showsReads)
                    .toggleStyle(.checkbox)
                    .hint("Also show read-only commands: git status, simctl list and similar")
                Button("Copy All", systemImage: "doc.on.doc") {
                    toaster.copy(OutputEntryMapper.transcript(for: entries), label: "Output")
                }
                .disabled(entries.isEmpty)
                Button("Clear", systemImage: "trash") {
                    commandLog.clear()
                }
                IconButton(systemImage: "chevron.down", help: "Hide output") {
                    output.isVisible = false
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if expandedIDs.contains(id) {
            expandedIDs.remove(id)
        } else {
            expandedIDs.insert(id)
        }
    }
}

#Preview {
    OutputPanel()
        .previewEnvironment()
}
