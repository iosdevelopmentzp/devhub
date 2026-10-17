import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionPrompt: View {
    @Environment(ConfigActionsStore.self) private var store

    let pending: PendingConfigAction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(pending.action.config.inputs ?? []) { input in
                ConfigActionInputField(input: input, value: binding(for: input))
            }
            if let confirm = pending.action.config.confirm {
                InlineConfirmation(
                    confirm,
                    confirmTitle: "Run",
                    confirmRole: nil,
                    systemImage: "questionmark.circle.fill",
                    tint: pending.action.config.tint == .red ? .red : .accentColor,
                    onCancel: { store.cancelPending() },
                    onConfirm: { store.confirmPending() }
                )
            } else {
                HStack {
                    Spacer()
                    Button("Cancel") {
                        store.cancelPending()
                    }
                    Button("Run") {
                        store.confirmPending()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .controlSize(.small)
            }
        }
        .padding(8)
        .background(Theme.base, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func binding(for input: ActionInput) -> Binding<String> {
        Binding(
            get: { store.pending?.inputs[input.key] ?? "" },
            set: { store.setInput($0, for: input.key) }
        )
    }
}

#Preview {
    ConfigActionPrompt(pending: PendingConfigAction(
        action: ResolvedAction(
            config: ActionConfig(id: "x", title: "Example", run: .open("x"), inputs: [ActionInput(key: "name", title: "Name", type: .text)], confirm: "Run it?"),
            origin: ActionOrigin(layer: .project, directory: "/repo/.devhub", fileName: "actions/x.json", isHeaderScript: false, isExecutable: true)
        ),
        slot: "preview",
        item: .none,
        inputs: [:]
    ))
    .padding()
    .previewEnvironment()
}
