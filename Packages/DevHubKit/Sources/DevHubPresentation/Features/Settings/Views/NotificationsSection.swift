import SwiftUI
import DevHubDomain
import DevHubUI

struct NotificationsSection: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(Notifier.self) private var notifier
    @Environment(\.codeHostWords) private var words

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle(isOn: $settings.values.notifyWhenPanelClosed) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notify while the panel is closed")
                    Text("The main switch. Off: no notification of the kinds below, except the script ones. Every event still goes to the Notifications list (the bell) and to Recent on Home.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(NotificationKind.allCases, id: \.self) { kind in
                Toggle(isOn: binding(for: kind)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NotificationKindText.title(for: kind, words: words))
                        Text(NotificationKindText.description(for: kind, words: words))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(settings.values.notifyWhenPanelClosed == false && kind.showsWhilePanelIsOpen == false)
            }
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
            Text("A click on a notification opens DevHub at the place it is about. While a build runs, the menu bar icon shows a circle; after a failure it shows a red dot until you open the panel.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task {
            await notifier.refreshPermission()
        }
    }

    private func binding(for kind: NotificationKind) -> Binding<Bool> {
        Binding(
            get: { settings.values.notifies(kind) },
            set: { settings.values.setNotifies(kind, $0) }
        )
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
