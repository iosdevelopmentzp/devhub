import SwiftUI

struct IconTile: View {
    let systemImage: String
    let tint: Tint
    let size: CGFloat

    init(systemImage: String, tint: Tint, size: CGFloat = 32) {
        self.systemImage = systemImage
        self.tint = tint
        self.size = size
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(tint.color)
            .frame(width: size, height: size)
            .background(tint.color.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.28))
    }
}

#Preview {
    IconTile(systemImage: "folder", tint: .blue)
        .padding()
}
