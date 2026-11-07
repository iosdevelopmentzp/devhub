import SwiftUI
import DevHubDomain
import DevHubUI

struct SimulatorRow<Panels: View>: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: SimulatorRowModel
    let onToggleIdentity: () -> Void
    let onToggleMessaging: () -> Void
    let onToggleQA: () -> Void
    let onToggleAppData: () -> Void
    let onRemoveApps: () -> Void
    let onTogglePower: () -> Void
    let onOpenInSimulator: () -> Void
    let onToggleFavorite: () -> Void
    let onLaunchAndAttach: () -> Void
    let onUninstall: () -> Void
    let onRequestErase: () -> Void
    let onCancelErase: () -> Void
    let onConfirmErase: () -> Void
    let onConfigAction: (ConfigActionItemModel.ID) -> Void
    @ViewBuilder var panels: () -> Panels

    var body: some View {
        RowContainer(verticalPadding: 7, isHighlighted: model.isHighlighted, highlight: .accentColor.opacity(0.1)) { isHovered in
            row(isHovered: isHovered)
        }
        .onTapGesture {
            appActions.selectBuildTarget(model.id)
        }
    }

    private func row(isHovered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                StatusDot(color: model.stateTint.color.opacity(model.stateDotOpacity))
                    .hint(model.stateText)
                Image(systemName: model.kindIcon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 22)

                details
                    .frame(maxWidth: .infinity, alignment: .leading)

                actions
                    .opacity(model.showsActions(isHovered: isHovered) ? 1 : 0)
            }

            panels()

            if model.isConfirmingErase {
                InlineConfirmation(
                    model.eraseConfirmation,
                    confirmTitle: "Erase",
                    confirmRole: .destructive,
                    onCancel: onCancelErase,
                    onConfirm: onConfirmErase
                )
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(model.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                ModelTag(model: model.runtimeTag)
                if let deviceTag = model.deviceTag {
                    ModelTag(model: deviceTag)
                }
                if let targetTag = model.targetTag {
                    ModelTag(model: targetTag)
                }
                if model.isFavorite {
                    Image(systemName: model.favoriteIcon)
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .hint(model.favoriteHint)
                }
            }
            Text(model.detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let status = model.status {
                SimulatorStatusLine(model: status)
            }
            if let identity = model.identity {
                IdentitySummary(model: identity)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 2) {
            if model.hasIdentityConfig {
                IconButton(systemImage: "person.text.rectangle", help: "Device ID and environment: see what the app uses now, set what the next launch uses", tint: .indigo) {
                    onToggleIdentity()
                }
            }
            if model.showsSimulatorActions {
                IconButton(systemImage: "paperplane", help: "Open a deep link or send a push to the app", tint: .teal) {
                    onToggleMessaging()
                }
                IconButton(systemImage: "slider.horizontal.3", help: "QA settings: appearance, text size, status bar, location, language, permissions, screenshot", tint: .purple) {
                    onToggleQA()
                }
            }
            IconButton(systemImage: "play.fill", help: model.showsSimulatorActions ? "Build & Run on this simulator" : "Build & Run on this device", tint: .green) {
                appActions.buildAndRun(on: model.id)
            }
            .disabled(model.canBuildAndRun == false)
            if model.isUninstalling {
                ProgressView()
                    .controlSize(.mini)
                    .frame(width: 24, height: 24)
            } else if model.showsSimulatorActions {
                IconButton(systemImage: "xmark.app", help: "Remove all installed apps (keeps settings)", tint: .red) {
                    onRemoveApps()
                }
                .disabled(model.canRemoveApps == false)
            }
            if model.showsSimulatorActions {
                IconButton(systemImage: "power", help: model.powerHint) {
                    onTogglePower()
                }
                .disabled(model.canTogglePower == false)
            }
            overflowMenu
        }
    }

    private var overflowMenu: some View {
        OverflowMenu {
            if model.showsSimulatorActions {
                Button(model.openAppTitle, systemImage: "macwindow") {
                    onOpenInSimulator()
                }
                Button("Stream App Logs", systemImage: "text.alignleft") {
                    appActions.streamLogs(simulatorID: model.id)
                }
                .disabled(model.canStreamLogs == false)
                Button("App Data…", systemImage: "externaldrive") {
                    onToggleAppData()
                }
                .disabled(model.canShowAppData == false)
            }
            Button(model.favoriteMenuTitle, systemImage: "star") {
                onToggleFavorite()
            }
            if model.hasIdentityConfig, model.showsSimulatorActions {
                Button("Launch & Attach Xcode", systemImage: "ladybug") {
                    onLaunchAndAttach()
                }
                .disabled(model.canLaunchAndAttach == false)
            }
            Button(model.uninstallTitle, systemImage: "xmark.app") {
                onUninstall()
            }
            .disabled(model.canUninstallFromMenu == false)
            if model.showsSimulatorActions {
                Button("Remove All Installed Apps", systemImage: "xmark.app.fill") {
                    onRemoveApps()
                }
                .disabled(model.canUninstallFromMenu == false)
            }
            Button("Copy UDID", systemImage: "doc.on.doc") {
                toaster.copy(model.id, label: model.copyUDIDLabel)
            }
            ConfigActionMenuItems(items: model.configActions, onRun: onConfigAction)
            if model.showsSimulatorActions {
                Divider()
                Button("Erase Content and Settings…", systemImage: "trash", role: .destructive) {
                    onRequestErase()
                }
                .disabled(model.canErase == false)
            }
        }
    }
}

#Preview {
    SimulatorRow(
        model: .preview,
        onToggleIdentity: {},
        onToggleMessaging: {},
        onToggleQA: {},
        onToggleAppData: {},
        onRemoveApps: {},
        onTogglePower: {},
        onOpenInSimulator: {},
        onToggleFavorite: {},
        onLaunchAndAttach: {},
        onUninstall: {},
        onRequestErase: {},
        onCancelErase: {},
        onConfirmErase: {},
        onConfigAction: { _ in }
    ) {
        EmptyView()
    }
    .frame(width: 700)
}
