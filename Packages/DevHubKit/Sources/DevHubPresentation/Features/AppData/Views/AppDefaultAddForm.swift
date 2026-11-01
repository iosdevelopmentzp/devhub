import SwiftUI
import DevHubDomain
import DevHubUI

struct AppDefaultAddForm: View {
    let suite: AppDefaultsSuite
    let onAdd: (String, AppDefaultValue) -> Void
    let onCancel: () -> Void

    @State private var key = ""
    @State private var kind = AppDefault.Kind.string
    @State private var text = ""

    private var value: AppDefaultValue? {
        AppDefaultsPolicy.value(kind: kind, text: text)
    }

    private var canAdd: Bool {
        value != nil && AppDefaultsPolicy.isValidKey(key, in: suite)
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("Key", text: $key)
                .textFieldStyle(.roundedBorder)
                .font(.caption.monospaced())
                .frame(minWidth: 120, maxWidth: 200)
            Picker("Type", selection: $kind) {
                ForEach(AppDefaultsPolicy.editableKinds, id: \.self) { kind in
                    Text(AppDataPanelMapper.kindTitle(kind)).tag(kind)
                }
            }
            .labelsHidden()
            .fixedSize()
            TextField(kind == .bool ? "true or false" : "Value", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.caption.monospaced())
                .onSubmit(add)
            Button("Add", action: add)
                .disabled(canAdd == false)
                .fixedSize()
            Button("Cancel", action: onCancel)
                .fixedSize()
        }
        .controlSize(.small)
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    private func add() {
        guard canAdd, let value else { return }
        onAdd(key.trimmingCharacters(in: .whitespacesAndNewlines), value)
    }
}

#Preview {
    AppDefaultAddForm(suite: AppDefaultsSuite(name: "com.example.app", plistPath: "/tmp/com.example.app.plist", entries: []), onAdd: { _, _ in }, onCancel: {})
        .frame(width: 640)
}
