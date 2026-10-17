import SwiftUI
import DevHubDomain
import DevHubUI

struct LocalBranchSectionHeader: View {
    let model: LocalBranchSectionModel
    let isCollapsed: Bool
    let cleanup: BranchCleanupModel?
    let progressText: String?
    let onToggle: (() -> Void)?
    let onCleanUp: (_ forceGone: Bool) -> Void

    @State private var isConfirming = false
    @State private var forceGone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ListSectionHeader(model.title, systemImage: chevron, detail: model.detail) {
                trailing
            }
            .contentShape(Rectangle())
            .onTapGesture { onToggle?() }
            if isConfirming, let cleanup {
                InlineConfirmation(
                    cleanup.title,
                    confirmTitle: "Delete",
                    confirmRole: .destructive,
                    onCancel: { isConfirming = false },
                    onConfirm: {
                        isConfirming = false
                        onCleanUp(forceGone)
                    },
                    details: {
                        Text(cleanup.names)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        if cleanup.showsForceToggle {
                            Toggle("Force-delete branches whose remote was deleted (-D)", isOn: $forceGone)
                                .toggleStyle(.checkbox)
                                .font(.caption)
                        }
                    },
                    extra: { EmptyView() }
                )
                .padding(.horizontal, 14)
            }
        }
    }

    private var chevron: String? {
        guard onToggle != nil else { return nil }
        return isCollapsed ? "chevron.right" : "chevron.down"
    }

    @ViewBuilder
    private var trailing: some View {
        if let progressText {
            ProgressView()
                .controlSize(.mini)
            Text(progressText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if cleanup != nil {
            Button("Delete all…") {
                forceGone = false
                isConfirming = true
            }
            .buttonStyle(LinkButtonStyle(.accent))
            .foregroundStyle(.red)
            .hint("Delete every merged branch in this list that is not checked out. dev, main and master stay.")
        }
    }
}

#Preview {
    LocalBranchSectionHeader(
        model: LocalBranchSectionModel(id: .merged, title: "Merged · safe to delete", detail: "212", rows: []),
        isCollapsed: true,
        cleanup: .preview,
        progressText: nil,
        onToggle: {},
        onCleanUp: { _ in }
    )
    .frame(width: 600)
    .background(Theme.surface)
}
