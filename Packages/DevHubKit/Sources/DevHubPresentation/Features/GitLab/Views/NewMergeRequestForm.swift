import SwiftUI
import DevHubDomain
import DevHubUI

struct NewMergeRequestForm: View {
    @Environment(NewMergeRequestStore.self) private var store
    @Environment(AppActions.self) private var appActions

    var body: some View {
        if let draft = store.draft {
            content(draft, model: NewMergeRequestMapper.model(for: draft))
                .padding(10)
                .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func content(_ draft: NewMergeRequestDraft, model: NewMergeRequestFormModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.pull")
                    .foregroundStyle(.blue)
                Text(model.heading)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Picker("Into", selection: binding(\.targetBranch)) {
                    ForEach(draft.targets, id: \.self) { Text($0).tag($0) }
                }
                .fixedSize()
                .hint("Target branch")
            }
            TextField("Title", text: binding(\.title))
                .textFieldStyle(.roundedBorder)
            PlainTextEditor(text: binding(\.description))
                .frame(minHeight: 90, maxHeight: 180)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.border))
            FlowLayout(spacing: 10, lineSpacing: 4) {
                Toggle("Draft", isOn: binding(\.isDraft))
                Toggle("Delete source branch after merge", isOn: binding(\.removeSourceBranch))
                Toggle("Squash", isOn: binding(\.squash))
            }
            .toggleStyle(.checkbox)
            .font(.caption)
            if draft.availableLabels.isEmpty == false {
                FlowLayout(spacing: 10, lineSpacing: 4) {
                    Text("Labels")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(draft.availableLabels, id: \.self) { label in
                        Toggle(label, isOn: Binding(get: { draft.labels.contains(label) }, set: { _ in store.toggleLabel(label) }))
                            .toggleStyle(.checkbox)
                            .font(.caption)
                    }
                }
            }
            if let error = draft.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            HStack(spacing: 8) {
                Button("Open in GitLab Instead") {
                    appActions.openNewMergeRequest(for: draft.sourceBranch, target: draft.targetBranch)
                    store.cancel()
                }
                .buttonStyle(LinkButtonStyle(.secondary))
                Spacer()
                if let busyText = model.busyText {
                    ProgressView()
                        .controlSize(.mini)
                    Text(busyText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Cancel") { store.cancel() }
                Button(model.createTitle) { appActions.createMergeRequest() }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.canCreate == false)
                    .hint(model.createHint)
            }
            .controlSize(.small)
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<NewMergeRequestDraft, Value>) -> Binding<Value> where Value: Equatable {
        Binding(
            get: { store.draft.map { $0[keyPath: keyPath] } ?? NewMergeRequestDraft.preview[keyPath: keyPath] },
            set: { store.draft?[keyPath: keyPath] = $0 }
        )
    }
}

#Preview {
    NewMergeRequestForm()
        .padding()
        .frame(width: 680)
        .previewEnvironment()
}
