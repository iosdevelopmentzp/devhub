import CoreGraphics

nonisolated enum ActionBarFit {
    static func labeled(priorities: [Int], labeledWidths: [CGFloat], iconWidths: [CGFloat], spacing: CGFloat, available: CGFloat?) -> Set<Int> {
        let byPriority = priorities.indices.sorted { priorities[$0] > priorities[$1] }
        guard let available else { return Set(byPriority) }
        for count in stride(from: byPriority.count, through: 0, by: -1) {
            let labeled = Set(byPriority.prefix(count))
            if width(labeled: labeled, labeledWidths: labeledWidths, iconWidths: iconWidths, spacing: spacing) <= available {
                return labeled
            }
        }
        return []
    }

    static func width(labeled: Set<Int>, labeledWidths: [CGFloat], iconWidths: [CGFloat], spacing: CGFloat) -> CGFloat {
        let widths = iconWidths.indices.map { labeled.contains($0) ? labeledWidths[$0] : iconWidths[$0] }
        return widths.reduce(0, +) + spacing * CGFloat(max(widths.count - 1, 0))
    }
}
