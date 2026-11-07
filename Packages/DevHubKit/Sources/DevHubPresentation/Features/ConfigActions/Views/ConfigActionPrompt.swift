import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionPrompt: View {
    @Environment(ConfigActionsStore.self) private var store

    let pending: PendingConfigAction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(pending.action.config.inputs ?? []) { input in
                ConfigActionInputField(input: input, value: binding(for: input), recent: recent(for: input))
            }
            if let preview = store.copyPreview(for: pending) {
                Text(preview)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .hint("What \(runTitle) puts on the clipboard")
            }
            if let confirm = store.confirmation(for: pending) {
                InlineConfirmation(
                    confirm,
                    confirmTitle: runTitle,
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
                    Button(runTitle) {
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

    private var runTitle: String {
        pending.action.config.run.copyTemplate == nil ? "Run" : "Copy"
    }

    private func binding(for input: ActionInput) -> Binding<String> {
        Binding(
            get: { store.pending?.inputs[input.key] ?? "" },
            set: { store.setInput($0, for: input.key) }
        )
    }

    private func recent(for input: ActionInput) -> RecentInputValues? {
        guard input.recent == true else { return nil }
        let scope = store.actionScope(pending.action.id)
        return RecentInputValues(
            values: store.recentValues(for: input.key, scope: scope),
            forget: { store.forgetRecent($0, for: input.key, scope: scope) }
        )
    }
}

#Preview {
    ConfigActionPrompt(pending: PendingConfigAction(
        action: ResolvedAction(
            config: ActionConfig(id: "x", title: "Example", run: .copy("hello {name}", open: nil), inputs: [ActionInput(key: "name", title: "Name", type: .text, recent: true)], confirm: "Copy it?"),
            origin: ActionOrigin(layer: .project, directory: "/repo/.devhub", fileName: "actions/x.json", isHeaderScript: false, isExecutable: true)
        ),
        slot: "preview",
        item: .none,
        inputs: ["name": "sam"]
    ))
    .padding()
    .previewEnvironment()
}
