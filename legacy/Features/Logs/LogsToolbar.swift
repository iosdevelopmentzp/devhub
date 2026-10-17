import SwiftUI

struct LogsToolbar: View {
    @Environment(LogsStore.self) private var store
    @Environment(Toaster.self) private var toaster
    @Environment(ActionCatalog.self) private var catalog
    @Environment(ActionRunner.self) private var runner

    static let slot = "logs.toolbar"

    let stream: LogStream
    let visible: [LogLine]

    private var actions: [CatalogAction] {
        catalog.actions(for: .logsToolbar)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LogFilterFields(stream: stream)
            HStack(spacing: 8) {
                levelPicker
                Spacer(minLength: 0)
                ActionBar(items: items)
            }
            if let pending = runner.pending(in: Self.slot) {
                ActionPrompt(pending: pending)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.base)
    }

    private var levelPicker: some View {
        Picker("Level", selection: Binding(get: { stream.level }, set: { store.setLevel($0, for: stream.id) })) {
            ForEach(LogLevelFilter.allCases, id: \.self) { level in
                Text(level.title).tag(level)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.small)
        .frame(maxWidth: 260)
    }

    private var items: [ActionItem] {
        streamItems + actions.map(configItem)
    }

    private var streamItems: [ActionItem] {
        let run = stream.isRunning
        let pause = stream.isPaused
        return [
            ActionItem(
                run ? "Stop" : "Start",
                systemImage: run ? "stop.fill" : "play.fill",
                hint: run ? "Stop this stream" : "Start this stream",
                priority: 5,
                isDisabled: false
            ) { run ? store.stop(stream.id) : store.start(stream.id) },
            ActionItem(
                pause ? "Resume (\(stream.pending.count))" : "Pause",
                systemImage: pause ? "play.circle" : "pause.circle",
                hint: pause ? "Show \(stream.pending.count) waiting lines" : "Hold new lines",
                priority: 3,
                isDisabled: false
            ) { store.togglePause(stream.id) },
            ActionItem("Copy", systemImage: "doc.on.doc", hint: "Copy \(visible.count) visible lines", priority: 2, isDisabled: visible.isEmpty) {
                toaster.copy(visible.map(\.plainText).joined(separator: "\n"), label: "\(visible.count) lines")
            },
            ActionItem("Clear", systemImage: "trash", hint: "Clear the lines", priority: 1, isDisabled: stream.lines.isEmpty && stream.pending.isEmpty) {
                store.clear(stream.id)
            }
        ]
    }

    private func configItem(_ action: CatalogAction) -> ActionItem {
        let context = ActionItemContext(simulatorUDID: stream.id, simulatorName: stream.name)
        return ActionItem(action.title, systemImage: action.systemImage, hint: action.subtitle.isEmpty ? action.title : action.subtitle, priority: 4, isDisabled: runner.isRunning(action)) {
            runner.request(action, item: context, slot: Self.slot)
        }
    }
}

#Preview {
    LogsToolbar(stream: LogStream(simulatorID: "A", name: "iPhone 17", process: "App", subsystem: "", level: .all), visible: [])
        .previewEnvironment()
}
