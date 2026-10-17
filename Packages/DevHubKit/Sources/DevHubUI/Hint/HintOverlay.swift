import SwiftUI

package struct HintOverlay: View {
    package let center: HintCenter

    @State private var bubbleSize: CGSize = .zero
    @State private var measuredID: UUID?

    package init(center: HintCenter) {
        self.center = center
    }

    package var body: some View {
        GeometryReader { proxy in
            if let hint = center.current {
                let root = proxy.frame(in: .global)
                let target = hint.frame.offsetBy(dx: -root.minX, dy: -root.minY)
                HintBubble(text: hint.text)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                        bubbleSize = size
                        measuredID = hint.id
                    }
                    .position(position(for: target, in: proxy.size))
                    .opacity(measuredID == hint.id ? 1 : 0)
                    .id(hint.id)
            }
        }
        .allowsHitTesting(false)
    }

    private func position(for target: CGRect, in container: CGSize) -> CGPoint {
        let gap: CGFloat = 6
        let margin: CGFloat = 8
        let halfWidth = bubbleSize.width / 2
        let halfHeight = bubbleSize.height / 2
        let x = min(max(target.midX, halfWidth + margin), container.width - halfWidth - margin)
        let below = target.maxY + gap + halfHeight
        let y = below + halfHeight + margin > container.height ? target.minY - gap - halfHeight : below
        return CGPoint(x: x, y: y)
    }
}
