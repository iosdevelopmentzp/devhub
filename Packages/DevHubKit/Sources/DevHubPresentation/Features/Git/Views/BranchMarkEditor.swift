import SwiftUI
import DevHubDomain
import DevHubUI

struct BranchMarkEditor: View {
    let branch: String
    let knownLabels: [String]
    let onCancel: () -> Void
    let onSave: (_ labels: [String], _ note: String) -> Void

    @State private var draft: BranchMarkDraft

    init(
        branch: String,
        draft: BranchMarkDraft,
        knownLabels: [String],
        onCancel: @escaping () -> Void,
        onSave: @escaping (_ labels: [String], _ note: String) -> Void
    ) {
        self.branch = branch
        self.knownLabels = knownLabels
        self.onCancel = onCancel
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .foregroundStyle(.blue)
                Text(branch)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            let options = draft.options(known: knownLabels)
            if options.isEmpty == false {
                FlowLayout(spacing: 10, lineSpacing: 4) {
                    Text("Labels")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(options, id: \.self) { label in
                        Toggle(label, isOn: Binding(get: { draft.isSelected(label) }, set: { _ in draft.toggle(label) }))
                            .toggleStyle(.checkbox)
                            .font(.caption)
                    }
                }
            }
            TextField("New label: review, demo, after release…", text: $draft.newLabel)
                .textFieldStyle(.roundedBorder)
                .onSubmit { draft.addNewLabel() }
            TextField("Note", text: $draft.note, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 8) {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { onSave(draft.finalLabels, draft.note) }
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.small)
        }
        .padding(10)
        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    BranchMarkEditor(
        branch: "feature/ABC-123-short-title",
        draft: BranchMarkDraft(mark: BranchMark(labels: ["demo"], note: "Waits for the backend fix")),
        knownLabels: ["demo", "review", "after release"],
        onCancel: {},
        onSave: { _, _ in }
    )
    .padding()
    .frame(width: 680)
}
