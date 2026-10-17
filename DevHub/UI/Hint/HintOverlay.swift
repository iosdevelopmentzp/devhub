import SwiftUI

struct HintOverlay: View {
    @Environment(HintCenter.self) private var center

    @State private var bubbleSize = CGSize.zero

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if let hint = center.current {
                    bubble(for: hint)
                        .onGeometryChange(for: CGSize.self) { $0.size } action: { bubbleSize = $0 }
                        .offset(offset(for: hint, container: proxy.frame(in: .global)))
                        .opacity(bubbleSize == .zero ? 0 : 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .allowsHitTesting(false)
    }

    private func bubble(for hint: Hint) -> some View {
        Text(hint.text)
            .font(.caption)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: 260, alignment: .leading)
            .fixedSize()
            .background(Theme.bubble, in: RoundedRectangle(cornerRadius: 6))
    }

    private func offset(for hint: Hint, container: CGRect) -> CGSize {
        let local = CGRect(
            x: hint.frame.minX - container.minX,
            y: hint.frame.minY - container.minY,
            width: hint.frame.width,
            height: hint.frame.height
        )
        let below = local.maxY + 6
        let fitsBelow = below + bubbleSize.height <= container.height - 8
        let y = fitsBelow ? below : local.minY - 6 - bubbleSize.height
        let x = min(max(local.midX - bubbleSize.width / 2, 8), max(8, container.width - bubbleSize.width - 8))
        return CGSize(width: x, height: max(8, y))
    }
}
