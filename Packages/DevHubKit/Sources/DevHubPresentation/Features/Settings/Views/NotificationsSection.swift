import SwiftUI
import DevHubDomain
import DevHubUI

struct NotificationsSection: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(Notifier.self) private var notifier

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle("Notify when the panel is closed", isOn: $settings.values.notifyWhenPanelClosed)
                .hint("A finished or failed build and new requests for your review show a macOS notification while the DevHub panel is closed")
            LabeledContent("Permission") {
                HStack(spacing: 8) {
                    Text(permissionText)
                        .foregroundStyle(notifier.permission == .denied ? Tint.orange.color : .secondary)
                    if notifier.permission == .notAsked {
                        Button("Allow Notifications") {
                            Task { await notifier.requestPermission() }
                        }
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("A script can also send one with a notify line. While a build runs, the menu bar icon shows a circle; after a failure it shows a red dot until you open the panel.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task {
            await notifier.refreshPermission()
        }
    }

    private var permissionText: String {
        switch notifier.permission {
        case .notAsked: "Not asked yet"
        case .allowed: "Allowed"
        case .denied: "Denied: allow DevHub in System Settings → Notifications"
        }
    }
}

#Preview {
    Form {
        NotificationsSection()
    }
    .formStyle(.grouped)
    .previewEnvironment()
}
