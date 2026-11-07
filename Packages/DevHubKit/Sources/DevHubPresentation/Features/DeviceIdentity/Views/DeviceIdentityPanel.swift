import SwiftUI
import DevHubDomain
import DevHubUI

struct DeviceIdentityPanel: View {
    @Environment(Toaster.self) private var toaster

    let model: IdentityPanelModel
    @Binding var deviceID: String
    @Binding var alias: String
    let onForget: (String) -> Void
    let newID: () -> String
    let onRefresh: () async -> Void
    let onLaunch: (_ attachDebugger: Bool) -> Void
    let onClose: () -> Void

    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            actualSection
            Divider()
            desiredSection
        }
        .padding(10)
        .background(Color.indigo.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.indigo.opacity(0.18)))
        .controlSize(.small)
        .task {
            await onRefresh()
        }
    }

    // MARK: Actual

    private var actualSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Now on this simulator")
                    .font(.caption.weight(.semibold))
                if let lastLaunchText = model.lastLaunchText {
                    Text(lastLaunchText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                }
                IconButton(systemImage: "arrow.clockwise", help: "Read the installed app again") {
                    refresh()
                }
            }
            if model.isInstalled {
                details
            } else {
                Text(model.notInstalledText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var details: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
            GridRow {
                FieldLabel("Profile")
                HStack(spacing: 6) {
                    ModelTag(model: model.profileTag)
                    if let profileNote = model.profileNote {
                        Text(profileNote)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let host = model.host {
                        Text(host)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            GridRow {
                FieldLabel("ID")
                HStack(spacing: 6) {
                    if let deviceAlias = model.deviceAlias {
                        Text(deviceAlias)
                            .font(.caption.weight(.semibold))
                    }
                    copyable(model.deviceID, placeholder: model.deviceIDPlaceholder)
                }
            }
            GridRow {
                FieldLabel("User")
                if let user = model.user {
                    copyable(user, placeholder: "")
                } else {
                    Text(model.userPlaceholder)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            GridRow {
                FieldLabel("App")
                HStack(spacing: 6) {
                    Text(model.version)
                        .font(.caption)
                    ModelTag(model: model.hooksTag)
                }
            }
        }
    }

    // MARK: Desired

    private var desiredSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LaunchIdentityControls(model: model.launch, deviceID: $deviceID, alias: $alias, onForget: onForget, newID: newID)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                CleanInstallNote(model: model.cleanInstallNote)
                Spacer()
                Button("Close", action: onClose)
                if model.canAttach {
                    Button("Launch & Attach", systemImage: "ladybug") {
                        onLaunch(true)
                    }
                    .disabled(model.canLaunch == false)
                    .hint("Launch the installed app frozen and attach Xcode, no build")
                }
                Button(model.launchTitle) {
                    onLaunch(false)
                }
                .buttonStyle(.borderedProminent)
                .tint(model.launchTint?.color ?? .accentColor)
                .disabled(model.canLaunch == false)
                .hint("Launch the installed app with these settings. Use Build & Run to build first.")
            }
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func copyable(_ value: String?, placeholder: String) -> some View {
        if let value {
            HStack(spacing: 4) {
                Text(value)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                IconButton(systemImage: "doc.on.doc", help: "Copy") {
                    toaster.copy(value)
                }
            }
        } else {
            Text(placeholder)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func refresh() {
        isRefreshing = true
        Task {
            await onRefresh()
            isRefreshing = false
        }
    }
}

#Preview {
    DeviceIdentityPanel(
        model: .preview,
        deviceID: .constant(""),
        alias: .constant(""),
        onForget: { _ in },
        newID: { "devhub-1a2b3c4d" },
        onRefresh: {},
        onLaunch: { _ in },
        onClose: {}
    )
    .padding()
    .frame(width: 680)
}
