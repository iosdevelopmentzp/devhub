import SwiftUI

struct PushForm: View {
    @Environment(SimulatorsStore.self) private var store
    @Environment(BuildStore.self) private var build

    let simulator: SimulatorInfo

    @State private var bundleID = ""
    @State private var payload = PushPayload.alertTemplate
    @State private var isSending = false

    private var problem: String? { PushPayload.problem(in: payload) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Bundle ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("com.example.app", text: $bundleID)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout.monospaced())
            }
            TextEditor(text: $payload)
                .font(.caption.monospaced())
                .frame(height: 130)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border))
            HStack(spacing: 6) {
                Button("Alert") { payload = PushPayload.alertTemplate }
                    .hint("Insert an alert notification")
                Button("Silent") { payload = PushPayload.silentTemplate }
                    .hint("Insert a background notification")
                if let problem {
                    Label(problem, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Tint.orange.color)
                        .lineLimit(1)
                } else {
                    Label("Valid JSON", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Tint.green.color)
                }
                Spacer(minLength: 0)
                Button("Send") { send() }
                    .buttonStyle(.borderedProminent)
                    .disabled(problem != nil || bundleID.isEmpty || isSending)
            }
            .controlSize(.small)
        }
        .onAppear {
            if bundleID.isEmpty {
                bundleID = build.bundleID ?? ""
            }
        }
    }

    private func send() {
        isSending = true
        Task {
            _ = await store.sendPush(payload, bundleID: bundleID, to: simulator)
            isSending = false
        }
    }
}

#Preview {
    PushForm(simulator: SimulatorInfo(id: "A", name: "iPhone 17", runtime: "iOS 26.0", state: .booted, appCount: 1, isFavorite: false))
        .padding()
        .frame(width: 360)
        .previewEnvironment()
}
