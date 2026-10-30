import SwiftUI
import DevHubDomain
import DevHubUI

struct SchemeEditor: View {
    let model: SchemeEditorModel
    let onAdd: (String) -> Void
    let onRemove: (String) -> Void
    let onDone: () -> Void

    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Scheme or target name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout.monospaced())
                    .onSubmit(addTyped)
                Button("Add", action: addTyped)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Done", action: onDone)
                    .keyboardShortcut(.cancelAction)
            }
            if model.suggestions.isEmpty == false {
                FlowLayout(spacing: 6, lineSpacing: 4) {
                    FieldLabel("In the project")
                    ForEach(model.suggestions, id: \.self) { suggestion in
                        Button {
                            onAdd(suggestion)
                        } label: {
                            Label(suggestion, systemImage: "plus")
                                .font(.caption.monospaced())
                        }
                        .hint("Add \(suggestion) to the scheme list")
                    }
                }
            }
            if let message = model.message {
                HStack(spacing: 6) {
                    if model.isLoading {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if model.manual.isEmpty == false {
                FlowLayout(spacing: 6, lineSpacing: 4) {
                    FieldLabel("Added by you")
                    ForEach(model.manual, id: \.self) { scheme in
                        HStack(spacing: 2) {
                            Text(scheme)
                                .font(.caption.monospaced())
                            IconButton(systemImage: "xmark", help: "Remove \(scheme) from the scheme list") {
                                onRemove(scheme)
                            }
                        }
                        .padding(.leading, 6)
                        .background(Theme.hover, in: Capsule())
                    }
                }
            }
        }
        .controlSize(.small)
        .padding(10)
        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func addTyped() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        onAdd(trimmed)
        name = ""
    }
}

#Preview {
    SchemeEditor(model: .preview, onAdd: { _ in }, onRemove: { _ in }, onDone: {})
        .padding()
        .frame(width: 680)
}
