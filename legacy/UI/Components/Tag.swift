import SwiftUI

struct Tag: View {
    let text: String
    let tint: Tint
    let systemImage: String?

    init(_ text: String, tint: Tint, systemImage: String? = nil) {
        self.text = text
        self.tint = tint
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(tint.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tint.color.opacity(0.14), in: Capsule())
        .fixedSize()
    }
}

#Preview {
    Tag("clean", tint: .green, systemImage: "checkmark")
        .padding()
}
