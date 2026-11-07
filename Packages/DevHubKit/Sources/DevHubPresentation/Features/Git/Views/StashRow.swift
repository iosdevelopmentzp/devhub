import SwiftUI
import DevHubDomain
import DevHubUI

struct StashRow: View {
    @Environment(Toaster.self) private var toaster

    let model: StashRowModel
    let onToggle: () -> Void
    let onToggleFile: (_ path: String) -> Void
    let onApply: () -> Void
    let onPop: () -> Void
    let onDrop: () -> Void
    let onBranch: (_ name: String) -> Void

    @State private var isConfirmingDrop = false
    @State private var isNamingBranch = false
    @State private var branchName = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowContainer(verticalPadding: 7) { isHovered in
                VStack(alignment: .leading, spacing: 6) {
                    summary(isHovered: isHovered)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onToggle)
                    if isConfirmingDrop {
                        InlineConfirmation(
                            model.dropMessage,
                            confirmTitle: "Drop",
                            confirmRole: .destructive,
                            onCancel: { isConfirmingDrop = false },
                            onConfirm: {
                                isConfirmingDrop = false
                                onDrop()
                            }
                        )
                    }
                    if isNamingBranch {
                        branchEditor
                    }
                }
            }
            .contextMenu { menu }
            if let files = model.files {
                CommitFilesList(files: files, onToggleFile: onToggleFile)
                    .padding(.leading, 18)
                    .padding(.bottom, 6)
            }
        }
        .animation(.snappy(duration: 0.18), value: isNamingBranch)
    }

    private func summary(isHovered: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: model.isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 10)
                .padding(.top, 4)
            Image(systemName: "tray.full")
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.message)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .hintWhenTruncated(model.message)
                HStack(spacing: 6) {
                    Text(model.reference)
                        .font(.caption2.monospaced())
                        .copyOnClick(model.reference, label: model.reference)
                    if let branch = model.branch {
                        Text(branch)
                            .font(.caption2.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    if let dateText = model.dateText {
                        Text(dateText)
                            .font(.caption2.weight(.medium))
                    }
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            HoverActions(isVisible: isHovered && isConfirmingDrop == false && isNamingBranch == false, count: 3, spacing: 2) {
                IconButton(systemImage: "tray.and.arrow.up", help: "Apply: bring the changes back and keep the stash") {
                    onApply()
                }
                IconButton(systemImage: "arrow.uturn.up", help: "Pop: bring the changes back and drop the stash") {
                    onPop()
                }
                IconButton(systemImage: "trash", help: "Drop the stash", tint: .red) {
                    isConfirmingDrop = true
                }
            }
            .disabled(model.areActionsEnabled == false)
        }
    }

    private var branchEditor: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(.secondary)
            TextField(model.branchPlaceholder, text: $branchName)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .focused($isNameFocused)
                .onSubmit(createBranch)
                .onExitCommand { isNamingBranch = false }
            Button("Create Branch", action: createBranch)
                .controlSize(.small)
                .fixedSize()
                .disabled(branchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .hint("git stash branch <name> \(model.reference): a new branch from the commit the stash was made on, with the stash applied and dropped")
            Button("Cancel") { isNamingBranch = false }
                .controlSize(.small)
                .fixedSize()
        }
        .padding(.leading, 26)
        .onAppear { isNameFocused = true }
    }

    private func createBranch() {
        let name = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.isEmpty == false else { return }
        isNamingBranch = false
        branchName = ""
        onBranch(name)
    }

    @ViewBuilder
    private var menu: some View {
        Button(model.isExpanded ? "Hide Files" : "Show Files", systemImage: "doc.text", action: onToggle)
        Divider()
        Button("Apply", systemImage: "tray.and.arrow.up", action: onApply)
        Button("Pop", systemImage: "arrow.uturn.up", action: onPop)
        Button("Create Branch from Stash…", systemImage: "arrow.triangle.branch") { isNamingBranch = true }
        Divider()
        Button("Copy Hash", systemImage: "number") { toaster.copy(model.hash, label: model.reference) }
        Button("Copy Message", systemImage: "doc.on.doc") { toaster.copy(model.message, label: "Message") }
        Divider()
        Button("Drop…", systemImage: "trash", role: .destructive) { isConfirmingDrop = true }
    }
}

#Preview {
    StashRow(model: .preview, onToggle: {}, onToggleFile: { _ in }, onApply: {}, onPop: {}, onDrop: {}, onBranch: { _ in })
        .previewEnvironment()
}
