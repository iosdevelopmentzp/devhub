import SwiftUI

struct ActionPrompt: View {
    @Environment(ActionRunner.self) private var runner

    let pending: PendingRun

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(pending.action.inputs) { input in
                ActionInputField(input: input, value: binding(for: input))
            }
            if let confirm = pending.action.confirm {
                InlineConfirm(
                    text: confirm,
                    confirmTitle: "Run",
                    tint: pending.action.tint == .red ? .red : .blue,
                    onCancel: { runner.cancelPending() },
                    onConfirm: { runner.confirmPending() }
                )
            } else {
                HStack {
                    Spacer()
                    Button("Cancel") { runner.cancelPending() }
                    Button("Run") { runner.confirmPending() }
                        .buttonStyle(.borderedProminent)
                }
                .controlSize(.small)
            }
        }
        .padding(8)
        .background(Theme.base, in: RoundedRectangle(cornerRadius: 8))
    }

    private func binding(for input: ActionInput) -> Binding<String> {
        Binding(
            get: { runner.pending?.inputs[input.key] ?? "" },
            set: { runner.setInput($0, for: input.key) }
        )
    }
}

#Preview {
    ActionPrompt(pending: PendingRun(
        action: CatalogAction(builtin: .openFolder, title: "Example", subtitle: ""),
        slot: "preview",
        item: .none,
        inputs: [:]
    ))
    .padding()
    .previewEnvironment()
}
