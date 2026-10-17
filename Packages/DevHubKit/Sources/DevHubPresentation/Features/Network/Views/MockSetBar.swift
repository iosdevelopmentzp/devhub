import SwiftUI
import DevHubDomain
import DevHubUI

struct MockSetBar: View {
    let sets: [MockServerBarModel.SetOption]
    let selectedSetID: MockSet.ID?
    let selectedName: String?
    let onSelect: (MockSet.ID?) -> Void
    let onCreate: () -> Void
    let onRename: (String) -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onAddRule: () -> Void

    @State private var newName: String?
    @State private var isConfirmingDelete = false

    var body: some View {
        ToolbarBar {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if let newName {
                        renameField(newName)
                    } else {
                        picker
                    }
                    IconButton(systemImage: "plus.rectangle.on.folder", help: "New mock set", action: onCreate)
                    if selectedSetID != nil {
                        OverflowMenu {
                            Button("Rename…") { newName = selectedName ?? "" }
                            Button("Duplicate", action: onDuplicate)
                            Divider()
                            Button("Delete…", role: .destructive) { isConfirmingDelete = true }
                        }
                    }
                    Spacer(minLength: 6)
                    Button("Add Rule", systemImage: "plus", action: onAddRule)
                        .fixedSize()
                        .disabled(selectedSetID == nil)
                        .hint("Add a rule to this set and open it in the editor")
                }
                if isConfirmingDelete {
                    InlineConfirmation(
                        "Delete the mock set \(selectedName ?? "")? Its file and body files are removed from ~/.devhub/mocks.",
                        confirmTitle: "Delete",
                        confirmRole: .destructive,
                        onCancel: { isConfirmingDelete = false },
                        onConfirm: {
                            isConfirmingDelete = false
                            onDelete()
                        }
                    )
                }
            }
        }
    }

    private var picker: some View {
        Picker("Mock set", selection: Binding(get: { selectedSetID }, set: { onSelect($0) })) {
            if sets.isEmpty {
                Text("No mock sets").tag(MockSet.ID?.none)
            }
            ForEach(sets) { option in
                Text(option.title).tag(MockSet.ID?.some(option.id))
            }
        }
        .labelsHidden()
        .fixedSize()
        .hint("Sets are JSON files in ~/.devhub/mocks/<project>/")
    }

    private func renameField(_ name: String) -> some View {
        HStack(spacing: 6) {
            TextField("Set name", text: Binding(get: { name }, set: { newName = $0 }))
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 160, maxWidth: 240)
                .onSubmit(commitRename)
            Button("Cancel") { newName = nil }
                .fixedSize()
            Button("Rename", action: commitRename)
                .buttonStyle(.borderedProminent)
                .fixedSize()
        }
    }

    private func commitRename() {
        guard let newName else { return }
        onRename(newName)
        self.newName = nil
    }
}

#Preview {
    MockSetBar(
        sets: MockServerBarModel.preview.sets,
        selectedSetID: MockServerBarModel.preview.sets.first?.id,
        selectedName: "VIP user",
        onSelect: { _ in },
        onCreate: {},
        onRename: { _ in },
        onDuplicate: {},
        onDelete: {},
        onAddRule: {}
    )
    .previewEnvironment()
    .frame(width: 720)
}
