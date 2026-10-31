import SwiftUI
import DevHubDomain
import DevHubUI

struct OutputPanel: View {
    @Environment(OutputPanelState.self) private var output
    @Environment(CommandLog.self) private var commandLog
    @Environment(Toaster.self) private var toaster
    @Environment(WindowLayout.self) private var layout
    @Environment(AppActions.self) private var appActions

    @State private var expandedIDs: Set<UUID> = []
    @State private var query = ""
    @State private var failedOnly = false
    @State private var dragStartHeight: CGFloat?

    var body: some View {
        VStack(spacing: 0) {
            resizeHandle
            header
            Divider()
            list
        }
        .frame(height: output.height(inWindowOfHeight: layout.size.height))
        .background(Theme.surface)
    }

    private var entries: [CommandLog.Entry] {
        OutputEntryMapper.visibleEntries(commandLog.entries, showsReads: output.showsReads, failedOnly: failedOnly, query: query)
    }

    private var resizeHandle: some View {
        SplitHandle(
            axis: .horizontal,
            onDrag: { translation in
                let start = dragStartHeight ?? output.height(inWindowOfHeight: layout.size.height)
                dragStartHeight = start
                output.resize(to: start - translation, inWindowOfHeight: layout.size.height)
            },
            onEnd: { dragStartHeight = nil }
        )
        .onTapGesture(count: 2) {
            output.resetHeight()
        }
        .hint("Drag to change the height of the output. Double-click for the default height. The height is remembered.")
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
                    .frame(maxWidth: 180)
                filterMenu
                IconButton(
                    systemImage: "arrow.down.to.line",
                    help: output.followsOutput ? "Following: the list scrolls to the newest command and its new lines. Click to stop" : "Not following: the list stays where you scrolled. Click to follow new output again",
                    tint: output.followsOutput ? Color.accentColor : Color.primary
                ) {
                    output.followsOutput.toggle()
                }
                IconButton(systemImage: "doc.on.doc", help: "Copy every shown command with its folder, output and exit code") {
                    toaster.copy(OutputEntryMapper.transcript(for: entries), label: "Output")
                }
                .disabled(entries.isEmpty)
                IconButton(systemImage: "square.and.arrow.down", help: "Save every shown command with its folder, output and exit code to a file") {
                    appActions.saveText(OutputEntryMapper.transcript(for: entries), suggestedName: "devhub-output.log")
                }
                .disabled(entries.isEmpty)
                IconButton(systemImage: "trash", help: "Remove the finished commands from the log") {
                    commandLog.clear()
                }
                IconButton(systemImage: "chevron.down", help: "Hide output (⇧⌘O)") {
                    output.isVisible = false
                }
            }
        }
    }

    private var filterMenu: some View {
        @Bindable var output = output
        return Menu {
            Toggle("Show reads", isOn: $output.showsReads)
            Toggle("Failed only", isOn: $failedOnly)
            Divider()
            Toggle("Open When a Command Fails", isOn: $output.opensOnFailure)
        } label: {
            Image(systemName: failedOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(failedOnly ? Color.accentColor : Color.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .frame(width: 24, height: 24)
        .hint("Filter: also show read-only commands (git status, simctl list and similar), or show only the commands that failed")
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if entries.isEmpty {
                        Text(emptyText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(14)
                    }
                    ForEach(entries) { entry in
                        OutputEntryView(
                            model: OutputEntryMapper.model(for: entry, isExpanded: expandedIDs.contains(entry.id), now: .now),
                            transcript: OutputEntryMapper.transcript(for: entry),
                            onCopy: { toaster.copy(OutputEntryMapper.transcript(for: entry), label: "Command and output") },
                            onToggle: { toggle(entry.id) }
                        )
                        .id(entry.id)
                        Divider()
                    }
                }
            }
            .onChange(of: entries.last?.id) { _, last in
                scrollToEnd(proxy, id: last)
            }
            .onChange(of: entries.last?.lines.count) { _, _ in
                scrollToEnd(proxy, id: entries.last?.id)
            }
            .onChange(of: output.followsOutput) { _, follows in
                guard follows else { return }
                scrollToEnd(proxy, id: entries.last?.id)
            }
        }
    }

    private var emptyText: String {
        failedOnly ? "No failed command in the log." : "Commands DevHub runs appear here with their output."
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy, id: UUID?) {
        guard output.followsOutput, let id else { return }
        proxy.scrollTo(id, anchor: .bottom)
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
