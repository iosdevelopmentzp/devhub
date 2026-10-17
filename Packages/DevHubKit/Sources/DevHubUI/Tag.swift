import SwiftUI

package struct Tag: View {
    private let text: String
    private let tint: Color
    private let systemImage: String?

    package init(_ text: String, tint: Color = .secondary, systemImage: String? = nil) {
        self.text = text
        self.tint = tint
        self.systemImage = systemImage
    }

    package var body: some View {
        HStack(spacing: 3) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .semibold))
            }
            if text.isEmpty == false {
                Text(text)
                    .lineLimit(1)
            }
        }
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, text.isEmpty ? 4 : 6)
        .padding(.vertical, 2)
        .foregroundStyle(tint)
        .background(tint.opacity(0.14), in: Capsule())
        .fixedSize()
    }
}
