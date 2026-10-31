import SwiftUI
import DevHubUI

struct PullRequestFactsLine: View {
    let model: PullRequestRowModel
    let isNarrow: Bool

    var body: some View {
        Group {
            if isNarrow {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        author
                        date
                        stats
                    }
                    HStack(spacing: 6) {
                        branches
                    }
                }
            } else {
                HStack(spacing: 6) {
                    author
                    date
                    branches
                    stats
                }
            }
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var author: some View {
        if model.author.isEmpty == false {
            Label(model.author, systemImage: "person.crop.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(model.authorTint?.color ?? .primary)
                .lineLimit(1)
                .fixedSize()
                .hint(model.authorHint)
        }
    }

    @ViewBuilder
    private var date: some View {
        if let dateText = model.dateText {
            Text(dateText)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
                .fixedSize()
                .hint(model.dateHint)
        }
    }

    @ViewBuilder
    private var stats: some View {
        if let statsText = model.statsText {
            Text(statsText)
                .font(.caption2.monospacedDigit())
                .lineLimit(1)
                .fixedSize()
        }
    }

    @ViewBuilder
    private var branches: some View {
        Text(model.sourceBranch)
            .font(.caption2.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
            .copyOnClick(model.sourceBranch, label: model.sourceBranch)
        Image(systemName: "arrow.right")
            .font(.system(size: 8, weight: .semibold))
        Text(model.targetBranch)
            .font(.caption2.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
            .layoutPriority(1)
            .copyOnClick(model.targetBranch, label: model.targetBranch)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        PullRequestFactsLine(model: .preview, isNarrow: false)
        PullRequestFactsLine(model: .preview, isNarrow: true)
    }
    .previewEnvironment()
    .padding()
    .frame(width: 560)
}
