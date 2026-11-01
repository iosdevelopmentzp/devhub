import SwiftUI
import DevHubDomain
import DevHubUI

struct NewPullRequestForm: View {
    @Environment(NewPullRequestStore.self) private var store
    @Environment(AppActions.self) private var appActions
    @Environment(AITextStore.self) private var aiText
    @Environment(\.codeHostWords) private var words

    var body: some View {
        if let draft = store.draft {
            content(draft, model: NewPullRequestMapper.model(for: draft, words: words))
                .padding(10)
                .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func content(_ draft: NewPullRequestDraft, model: NewPullRequestFormModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.pull")
                    .foregroundStyle(.blue)
                Text(model.heading)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                AIWriteButton(
                    model: AIWriteButtonMapper.model(
                        title: "Write with AI",
                        purpose: "writes the title and the description from the diff, the commits and the template",
                        defaultProvider: aiText.defaultProvider,
                        isRunning: aiText.isRunning(.newRequest(branch: draft.sourceBranch)),
                        isEnabled: draft.isLoading == false
                    ),
                    onPick: { provider in
                        aiText.writePullRequest(draft, provider: provider) { title, body in
                            guard store.draft?.sourceBranch == draft.sourceBranch else { return }
                            if title.isEmpty == false {
                                store.draft?.title = title
                            }
                            if body.isEmpty == false {
                                store.draft?.description = body
                            }
                        }
                    },
                    onStop: { aiText.stop(.newRequest(branch: draft.sourceBranch)) }
                )
                Picker("Into", selection: binding(\.targetBranch)) {
                    ForEach(draft.targets, id: \.self) { Text($0).tag($0) }
                }
                .fixedSize()
                .hint("Target branch")
            }
            OperationSlot(origin: .newPullRequest)
            TextField("Title", text: binding(\.title))
                .textFieldStyle(.roundedBorder)
            PlainTextEditor(text: binding(\.description))
                .frame(minHeight: 90, maxHeight: 180)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.border))
            FlowLayout(spacing: 10, lineSpacing: 4) {
                Toggle("Draft", isOn: binding(\.isDraft))
                if model.showsMergeOptions {
                    Toggle("Delete source branch after merge", isOn: binding(\.removeSourceBranch))
                    Toggle("Squash", isOn: binding(\.squash))
                }
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
                Button("\(words.openTitle) Instead") {
                    appActions.openNewPullRequest(for: draft.sourceBranch, target: draft.targetBranch)
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
                Button(model.createTitle) { appActions.createPullRequest() }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.canCreate == false)
                    .hint(model.createHint)
            }
            .controlSize(.small)
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<NewPullRequestDraft, Value>) -> Binding<Value> where Value: Equatable {
        Binding(
            get: { store.draft.map { $0[keyPath: keyPath] } ?? NewPullRequestDraft.preview[keyPath: keyPath] },
            set: { store.draft?[keyPath: keyPath] = $0 }
        )
    }
}

#Preview {
    NewPullRequestForm()
        .padding()
        .frame(width: 680)
        .previewEnvironment()
}
