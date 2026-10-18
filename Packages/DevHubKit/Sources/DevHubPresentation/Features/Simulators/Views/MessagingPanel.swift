import SwiftUI
import DevHubDomain
import DevHubUI

struct MessagingPanel: View {
    @Environment(MessagingStore.self) private var messaging
    @Environment(ProjectSession.self) private var session

    let simulator: Simulator
    let onClose: () -> Void

    private var isBooted: Bool {
        simulator.state == .booted
    }

    var body: some View {
        @Bindable var messaging = messaging
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Deep link")
                    .font(.caption.weight(.semibold))
                    .frame(width: 70, alignment: .leading)
                TextField(messaging.schemes.first.map { $0 + "…" } ?? "myapp://…", text: $messaging.url)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout.monospaced())
                    .onSubmit { messaging.openURL(on: simulator) }
                Menu {
                    ForEach(messaging.schemes, id: \.self) { scheme in
                        Button(scheme) { messaging.url = scheme }
                    }
                    if messaging.urlHistory.isEmpty == false {
                        Section("Recent") {
                            ForEach(messaging.urlHistory, id: \.self) { value in
                                Button(value) { messaging.url = value }
                            }
                        }
                        Menu("Forget") {
                            ForEach(messaging.urlHistory, id: \.self) { value in
                                Button(value) { messaging.forget(url: value) }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .fixedSize()
                .hint("App URL schemes and the links you opened before")
                Button("Open", systemImage: "link") {
                    messaging.openURL(on: simulator)
                }
                .fixedSize()
                .disabled(isBooted == false || messaging.url.trimmed.isEmpty || messaging.isBusy(simulator.id))
                .hint("xcrun simctl openurl: the system opens the link like a tap in Safari or Notes")
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Push")
                        .font(.caption.weight(.semibold))
                    Text("to \(session.selectedProject.bundleID)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Menu("Templates") {
                        Button("Alert") { messaging.payload = messaging.alertTemplate }
                        Button("Silent (content-available)") { messaging.payload = MessagingStore.silentTemplate }
                        if messaging.payloadHistory.isEmpty == false {
                            Section("Recent") {
                                ForEach(Array(messaging.payloadHistory.enumerated()), id: \.offset) { index, value in
                                    Button(preview(value)) { messaging.payload = value }
                                }
                            }
                        }
                    }
                    .fixedSize()
                    .hint("Start from a template or a payload you sent before")
                }
                PlainTextEditor(text: $messaging.payload)
                    .padding(4)
                    .frame(height: 130)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(messaging.payloadError == nil ? Theme.border : Color.red.opacity(0.6)))
                HStack(spacing: 8) {
                    if let error = messaging.payloadError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if isBooted == false {
                        Text("Boot the simulator to open links and send pushes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("The app shows the alert only in the background. In the foreground it gets the payload in its notification delegate.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    if messaging.isBusy(simulator.id) {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    Button("Close", action: onClose)
                        .fixedSize()
                    Button("Send Push", systemImage: "paperplane.fill") {
                        messaging.sendPush(to: simulator)
                    }
                    .buttonStyle(.borderedProminent)
                    .fixedSize()
                    .disabled(isBooted == false || messaging.payloadError != nil || messaging.isBusy(simulator.id))
                    .hint("xcrun simctl push <udid> \(session.selectedProject.bundleID) <payload>")
                }
            }
        }
        .padding(10)
        .background(Color.teal.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.teal.opacity(0.2)))
        .controlSize(.small)
        .task(id: simulator.id) {
            await messaging.loadSchemes(for: simulator)
        }
    }

    private func preview(_ payload: String) -> String {
        let compact = payload.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
        return compact.count > 60 ? String(compact.prefix(57)) + "…" : compact
    }
}
