import SwiftUI
import DevHubDomain
import DevHubUI

struct LogsToolbar: View {
    @Environment(LogsStore.self) private var logs
    @Environment(Toaster.self) private var toaster

    let stream: LogStream
    let visibleLines: [AppLogLine]

    var body: some View {
        ToolbarBar {
            content
        }
    }

    private var content: some View {
        let model = LogsToolbarMapper.model(stream: stream, visibleLineCount: visibleLines.count)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Process", text: binding(\.process, logs.setProcess))
                    .textFieldStyle(.roundedBorder)
                    .font(.callout.monospaced())
                    .frame(minWidth: 90, maxWidth: 140)
                    .hint("The app's executable name. Found from the installed app when empty.")
                TextField("Subsystem", text: binding(\.subsystem, logs.setSubsystem))
                    .textFieldStyle(.roundedBorder)
                    .font(.callout.monospaced())
                    .frame(minWidth: 90, maxWidth: 180)
                    .hint("When set, the stream shows this subsystem instead of the process")
                runButton
                Spacer(minLength: 0)
                if stream.isRunning {
                    ProgressView()
                        .controlSize(.mini)
                    Text("live")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            HStack(spacing: 8) {
                Picker("Level", selection: Binding(get: { stream.minimumLevel }, set: { logs.setLevel($0, for: stream.id) })) {
                    Text("All").tag(AppLogLine.Level.debug)
                    Text("Info+").tag(AppLogLine.Level.info)
                    Text("Default+").tag(AppLogLine.Level.notice)
                    Text("Errors").tag(AppLogLine.Level.error)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 260)
                .hint("Hide lines below this level")
                Text(model.lineCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                if let dropped = model.droppedText {
                    Text(dropped)
                        .font(.caption)
                        .foregroundStyle(Tint.orange.color)
                        .fixedSize()
                        .hint("The list keeps the last \(LogStream.capacity) lines")
                }
                Spacer()
                Toggle(isOn: Binding(get: { stream.isPaused }, set: { logs.setPaused($0, for: stream.id) })) {
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
                    logs.clear(stream.id)
                }
                .disabled(model.canClear == false)
            }
            ConfigActionBar(placement: .logsToolbar, item: ActionItemContext(simulatorUDID: stream.id, simulatorName: stream.name))
        }
    }

    @ViewBuilder
    private var runButton: some View {
        if stream.isRunning {
            Button("Stop", systemImage: "stop.fill") {
                logs.stop(stream.id)
            }
            .fixedSize()
            .hint("Stop xcrun simctl spawn … log stream")
        } else {
            Button("Start", systemImage: "play.fill") {
                logs.start(stream.id)
            }
            .buttonStyle(.borderedProminent)
            .fixedSize()
            .hint("Stream the app's system log live: xcrun simctl spawn <udid> log stream")
        }
    }

    private func binding(_ keyPath: KeyPath<LogStream, String>, _ set: @escaping (String, Simulator.ID) -> Void) -> Binding<String> {
        let id = stream.id
        return Binding(get: { stream[keyPath: keyPath] }, set: { set($0, id) })
    }
}

#Preview {
    LogsToolbar(stream: LogStream(id: "A", name: "iPhone 17", process: "App", subsystem: "", minimumLevel: .debug), visibleLines: [])
        .previewEnvironment()
}
