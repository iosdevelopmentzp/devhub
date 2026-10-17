import SwiftUI

package struct PlainTag: View {
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
                    .font(.system(size: 10, weight: .medium))
            }
            if text.isEmpty == false {
                Text(text)
                    .lineLimit(1)
            }
        }
        .font(.caption)
        .foregroundStyle(tint)
        .fixedSize()
    }
}

#Preview {
    HStack(spacing: 10) {
        PlainTag("approved by Lee", systemImage: "checkmark.seal")
        PlainTag("2", systemImage: "bubble.left.and.bubble.right")
        PlainTag("conflicts", tint: .red, systemImage: "exclamationmark.triangle.fill")
    }
    .padding()
}
