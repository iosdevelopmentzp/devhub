import SwiftUI

struct SimulatorsSummaryBar: View {
    @Environment(SimulatorsStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(store.countText)
                    .font(.callout.weight(.semibold))
                if store.withAppsCount > 0 {
                    Tag("\(store.withAppsCount) with apps", tint: .blue)
                }
                Spacer(minLength: 8)
                if let removal = store.removal {
                    progress(removal)
                } else {
                    Button("Remove Apps from All…") { store.askRemoveAll() }
                        .controlSize(.small)
                        .disabled(store.withAppsCount == 0)
                        .fixedSize()
                        .hint("Uninstall every user app from every simulator")
                    IconButton(systemImage: "arrow.clockwise", help: "Refresh the simulator list") {
                        Task { await store.refresh() }
                    }
                }
            }
            if store.confirmation == .removeAll {
                InlineConfirm(
                    text: "Remove all user apps from \(store.withAppsCount) simulators? Shut-down devices are booted, cleaned and shut down again. This can take minutes.",
                    confirmTitle: "Remove apps",
                    tint: .red,
                    onCancel: { store.setConfirmation(nil) },
                    onConfirm: { store.startRemovingFromAll() }
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    private func progress(_ removal: RemovalProgress) -> some View {
        HStack(spacing: 8) {
            ProgressView(value: Double(removal.done), total: Double(max(removal.total, 1)))
                .progressViewStyle(.linear)
                .frame(width: 90)
            Text("\(removal.done + 1) of \(removal.total) · \(removal.name)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Button("Stop") { store.stopRemoving() }
                .controlSize(.small)
                .fixedSize()
        }
    }
}

#Preview {
    SimulatorsSummaryBar()
        .previewEnvironment()
}
