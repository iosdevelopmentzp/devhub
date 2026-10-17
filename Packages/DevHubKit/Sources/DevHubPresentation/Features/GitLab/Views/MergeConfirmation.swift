import SwiftUI
import DevHubUI

struct MergeConfirmation: View {
    let kind: MergeRequestActionModel.Kind
    let model: MergeRequestRowModel
    let onCancel: () -> Void
    let onMerge: (_ kind: MergeRequestActionModel.Kind, _ squash: Bool, _ removeSourceBranch: Bool) -> Void

    @State private var squash: Bool
    @State private var removeSourceBranch: Bool

    init(
        kind: MergeRequestActionModel.Kind,
        model: MergeRequestRowModel,
        onCancel: @escaping () -> Void,
        onMerge: @escaping (_ kind: MergeRequestActionModel.Kind, _ squash: Bool, _ removeSourceBranch: Bool) -> Void
    ) {
        self.kind = kind
        self.model = model
        self.onCancel = onCancel
        self.onMerge = onMerge
        _squash = State(initialValue: model.squashByDefault)
        _removeSourceBranch = State(initialValue: model.removeSourceBranchByDefault)
    }

    var body: some View {
        InlineConfirmation(
            kind == .mergeWhenPipelinePasses ? model.autoMergeTitle : model.mergeTitle,
            confirmTitle: "Merge",
            confirmRole: nil,
            systemImage: "arrow.triangle.merge",
            tint: .purple,
            onCancel: onCancel,
            onConfirm: { onMerge(kind, squash, removeSourceBranch) }
        ) {
            Toggle("Squash", isOn: $squash)
                .toggleStyle(.checkbox)
                .font(.caption)
            Toggle("Delete source branch", isOn: $removeSourceBranch)
                .toggleStyle(.checkbox)
                .font(.caption)
        }
    }
}

#Preview {
    MergeConfirmation(kind: .merge, model: .preview, onCancel: {}, onMerge: { _, _, _ in })
        .padding()
}
