import SwiftUI
import DevHubDomain
import DevHubUI

struct LogsToolbar: View {
    @Environment(LogsStore.self) private var logs
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(Toaster.self) private var toaster

    let visibleLines: [AppLogLine]

    var body: some View {
        ToolbarBar {
            content
        }
    }

    private var content: some View {
        @Bindable var logs = logs
        let model = model
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("Simulator", selection: $logs.selectedUDID) {
                    Text("Choose a booted simulator").tag(Simulator.ID?.none)
                    ForEach(model.simulators) { option in
                        Text(option.title).tag(Simulator.ID?.some(option.id))
                    }
                }
                .labelsHidden()
                .fixedSize()
                .hint("Only booted simulators can stream logs")
                TextField("Process", text: $logs.process)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout.monospaced())
                    .frame(width: 120)
                    .hint("The app's executable name. Found from the installed app, change it for another app.")
                if logs.isStreaming {
                    Button("Stop", systemImage: "stop.fill") {
                        logs.stop()
                    }
                    .fixedSize()
                    .hint("Stop xcrun simctl spawn … log stream")
                } else {
                    Button("Start", systemImage: "play.fill") {
                        logs.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .fixedSize()
                    .disabled(model.canStart == false)
                    .hint("Stream the app's system log live: xcrun simctl spawn <udid> log stream")
                }
                Spacer(minLength: 0)
                if logs.isStreaming {
                    ProgressView()
                        .controlSize(.mini)
                    Text("live")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            HStack(spacing: 8) {
                Picker("Level", selection: $logs.minimumLevel) {
                    Text("All").tag(AppLogLine.Level.debug)
                    Text("Info+").tag(AppLogLine.Level.info)
                    Text("Default+").tag(AppLogLine.Level.notice)
                    Text("Errors").tag(AppLogLine.Level.error)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 260)
                .hint("Hide lines below this level")
                Spacer()
                Toggle(isOn: $logs.isPaused) {
                    Label(model.pauseTitle, systemImage: "pause.fill")
                }
                .toggleStyle(.button)
                .fixedSize()
                .hint("Freeze the list to read it. New lines wait and appear when you resume.")
                IconButton(systemImage: "doc.on.doc", help: "Copy the visible lines") {
                    toaster.copy(LogsToolbarMapper.transcript(for: visibleLines), label: model.copyLabel)
                }
                .disabled(model.canCopy == false)
                IconButton(systemImage: "trash", help: "Clear the list") {
                    logs.clear()
                }
            }
        }
    }

    private var model: LogsToolbarModel {
        LogsToolbarMapper.model(
            simulators: simulators.all,
            runtime: simulators.runtime(for:),
            selectedUDID: logs.selectedUDID,
            process: logs.process,
            isPaused: logs.isPaused,
            pendingCount: logs.pendingCount,
            visibleLineCount: visibleLines.count
        )
    }
}

#Preview {
    LogsToolbar(visibleLines: [])
        .previewEnvironment()
}
