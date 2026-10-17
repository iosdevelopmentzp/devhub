import SwiftUI

struct LogFilterFields: View {
    @Environment(LogsStore.self) private var store

    let stream: LogStream

    var body: some View {
        HStack(spacing: 8) {
            field("Process", text: stream.process) { store.setProcess($0, for: stream.id) }
            field("Subsystem", text: stream.subsystem) { store.setSubsystem($0, for: stream.id) }
        }
        .disabled(stream.isRunning)
    }

    private func field(_ title: String, text: String, set: @escaping (String) -> Void) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: Binding(get: { text }, set: set))
                .textFieldStyle(.roundedBorder)
                .font(.caption.monospaced())
                .controlSize(.small)
        }
    }
}

#Preview {
    LogFilterFields(stream: LogStream(simulatorID: "A", name: "iPhone 17", process: "App", subsystem: "", level: .all))
        .padding()
        .previewEnvironment()
}
