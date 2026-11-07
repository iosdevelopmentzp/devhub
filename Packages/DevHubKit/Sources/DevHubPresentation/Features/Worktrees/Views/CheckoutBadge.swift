import SwiftUI
import DevHubDomain
import DevHubUI

struct CheckoutBadge: View {
    let model: CheckoutBadgeModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: model.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(model.text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(model.tint.color)
        .background(model.tint.color.opacity(model.isMain ? 0.1 : 0.16), in: Capsule())
        .overlay(Capsule().strokeBorder(model.tint.color.opacity(model.isMain ? 0.2 : 0.6)))
        .contentShape(Capsule())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        CheckoutBadge(model: .preview)
        CheckoutBadge(model: CheckoutBadgeModel(text: "Main checkout · dev", icon: "house", tint: .secondary, isMain: true, hint: ""))
    }
    .padding()
}
