import SwiftUI

struct OutputToolbar: View {
    @Environment(CommandLog.self) private var commandLog
    @Environment(OutputPanelState.self) private var output
    @Environment(Toaster.self) private var toaster

    let entries: [CommandEntry]

    var body: some View {
        @Bindable var output = output
        HStack(spacing: 10) {
            Text("Output · \(entries.count) \(entries.count == 1 ? "command" : "commands")")
                .font(.caption.weight(.semibold))
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Search output", text: $output.searchText)
                    .textFieldStyle(.plain)
                    .font(.caption)
            }
            .padding(.horizontal, 7)
            .frame(width: 180, height: 22)
            .background(Theme.base, in: RoundedRectangle(cornerRadius: 6))
            Toggle("Show reads", isOn: $output.showReads)
                .toggleStyle(.checkbox)
                .controlSize(.small)
                .hint("Show read-only commands such as git status")
            Button("Copy All") {
                toaster.copy(entries.reversed().map(\.plainText).joined(separator: "\n\n"), label: "output")
            }
            .controlSize(.small)
            .disabled(entries.isEmpty)
            Button("Clear") { commandLog.clear() }
                .controlSize(.small)
                .disabled(commandLog.entries.isEmpty)
            IconButton(systemImage: "chevron.down", help: "Hide the output panel") {
                output.isVisible = false
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(Theme.base)
    }
}

#Preview {
    OutputToolbar(entries: [])
        .previewEnvironment()
}
