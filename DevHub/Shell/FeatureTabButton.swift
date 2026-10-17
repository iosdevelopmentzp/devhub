import SwiftUI

struct FeatureTabButton: View {
    let feature: Feature
    let isSelected: Bool
    let showsTitle: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: feature.systemImage)
                    .font(.system(size: 12, weight: .medium))
                if showsTitle {
                    Text(feature.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .fixedSize()
        .onHover { isHovered = $0 }
        .hint(feature.title)
    }

    private var background: Color {
        if isSelected {
            return Color.accentColor
        }
        return isHovered ? Theme.hover : .clear
    }
}

#Preview {
    FeatureTabButton(feature: FeatureRegistry.all[0], isSelected: true, showsTitle: true) {}
        .padding()
        .previewEnvironment()
}
