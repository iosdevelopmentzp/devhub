import SwiftUI
import DevHubDomain
import DevHubUI

struct LaunchPicker: View {
    @Environment(BuildStore.self) private var build
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(IdentityStore.self) private var identityStore

    let subject: String
    let onCancel: () -> Void
    let onRun: (_ simulatorID: Simulator.ID) -> Void

    var body: some View {
        let model = model
        InlineConfirmation(
            model.title,
            confirmTitle: model.runTitle,
            confirmRole: nil,
            layout: .stacked(warnings: []),
            systemImage: "play.fill",
            tint: model.runTint.color,
            onCancel: onCancel,
            onConfirm: {
                guard model.canRun, let id = model.selectedID else { return }
                onCancel()
                onRun(id)
            }
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    FieldLabel("Simulator")
                    Picker("Simulator", selection: targetBinding(model)) {
                        ForEach(model.simulators) { option in
                            Text(option.title).tag(Optional(option.id))
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .hint("Booted simulators first, then favorites. The choice becomes the build target.")
                }
                if let launch = model.launch, let id = model.selectedID {
                    LaunchIdentityControls(
                        model: launch,
                        deviceID: deviceIDBinding(for: id),
                        alias: aliasBinding(for: id),
                        onForget: { identityStore.forgetSavedDeviceID($0) },
                        newID: { identityStore.newIdentity() }
                    )
                }
                if let note = model.cleanInstallNote {
                    CleanInstallNote(model: note)
                }
            }
        } extra: {
            EmptyView()
        }
        .task(id: model.selectedID) {
            guard let id = model.selectedID else { return }
            await identityStore.refresh(id: id)
        }
    }

    private var model: LaunchPickerModel {
        let targetID = build.target?.id
        return LaunchPickerMapper.model(
            subject: subject,
            simulators: simulators.all,
            runtime: { simulators.runtime(for: $0) },
            targetID: targetID,
            identity: targetID.flatMap { identityStore.context(for: $0) },
            cleanInstallIsOn: build.state.cleanInstall,
            buildIsRunning: build.isRunning
        )
    }

    private func targetBinding(_ model: LaunchPickerModel) -> Binding<Simulator.ID?> {
        Binding(
            get: { model.selectedID },
            set: { id in
                guard let id else { return }
                build.selectTarget(id: id)
            }
        )
    }

    private func deviceIDBinding(for id: Simulator.ID) -> Binding<String> {
        Binding(
            get: { identityStore.settings(for: id).desiredIdentity ?? "" },
            set: { identityStore.setDesiredDeviceID($0, for: id) }
        )
    }

    private func aliasBinding(for id: Simulator.ID) -> Binding<String> {
        Binding(
            get: { identityStore.alias(for: id) },
            set: { identityStore.setAlias($0, for: id) }
        )
    }
}

#Preview {
    LaunchPicker(subject: "feature/ABC-2324-paid-call", onCancel: {}, onRun: { _ in })
        .previewEnvironment()
        .padding()
        .frame(width: 700)
}
