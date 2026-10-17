import SwiftUI

package struct IconTile: View {
    package let systemImage: String
    package var tint: Color = .accentColor
    package var size: CGFloat = 30

    package init(systemImage: String, tint: Color = .accentColor, size: CGFloat = 30) {
        self.systemImage = systemImage
        self.tint = tint
        self.size = size
    }

    package var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}
