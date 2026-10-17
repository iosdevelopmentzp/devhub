import SwiftUI
import DevHubDomain
import DevHubUI

struct GitLabFilterBar: View {
    let chips: [MergeRequestFilterChipModel]
    let onRemove: (MergeRequestFilterChipModel.Kind) -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            FlowLayout(spacing: 6) {
                ForEach(chips) { chip in
                    RemovableChip(chip.title, systemImage: chip.systemImage, removeHint: "Remove this filter") {
                        onRemove(chip.kind)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if chips.count > 1 {
                Button("Clear all", action: onClear)
                    .buttonStyle(.link)
                    .font(.caption)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.base)
    }
}

#Preview {
    GitLabFilterBar(
        chips: [
            MergeRequestFilterChipModel(kind: .targetBranch, title: "into dev", systemImage: "arrow.triangle.branch"),
            MergeRequestFilterChipModel(kind: .onlyConflicts, title: "with conflicts", systemImage: "exclamationmark.triangle")
        ],
        onRemove: { _ in },
        onClear: {}
    )
    .frame(width: 720)
}
