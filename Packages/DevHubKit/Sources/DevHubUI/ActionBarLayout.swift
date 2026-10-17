import SwiftUI

struct ActionBarLayout: Layout {
    let priorities: [Int]
    let spacing: CGFloat

    struct Cache {
        var labeled: [CGSize]
        var icons: [CGSize]
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache(
            labeled: priorities.indices.map { subviews[2 * $0].sizeThatFits(.unspecified) },
            icons: priorities.indices.map { subviews[2 * $0 + 1].sizeThatFits(.unspecified) }
        )
    }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache = makeCache(subviews: subviews)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let labeled = labeledIndices(width: proposal.width, cache: cache)
        let width = ActionBarFit.width(labeled: labeled, labeledWidths: cache.labeled.map(\.width), iconWidths: cache.icons.map(\.width), spacing: spacing)
        let height = priorities.indices.map { labeled.contains($0) ? cache.labeled[$0].height : cache.icons[$0].height }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let labeled = labeledIndices(width: bounds.width, cache: cache)
        var x = bounds.minX
        for index in priorities.indices {
            let isLabeled = labeled.contains(index)
            let size = isLabeled ? cache.labeled[index] : cache.icons[index]
            subviews[isLabeled ? 2 * index : 2 * index + 1].place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(size))
            subviews[isLabeled ? 2 * index + 1 : 2 * index].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: .zero)
            x += size.width + spacing
        }
    }

    private func labeledIndices(width: CGFloat?, cache: Cache) -> Set<Int> {
        ActionBarFit.labeled(
            priorities: priorities,
            labeledWidths: cache.labeled.map(\.width),
            iconWidths: cache.icons.map(\.width),
            spacing: spacing,
            available: width
        )
    }
}
