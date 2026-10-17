import SwiftUI

package struct ListSectionHeader<Trailing: View>: View {
    private let title: String
    private let systemImage: String?
    private let iconTint: Color
    private let detail: String?
    private let topPadding: CGFloat
    private let bottomPadding: CGFloat
    private let trailing: Trailing

    package init(
        _ title: String,
        systemImage: String? = nil,
        iconTint: Color = .secondary,
        detail: String? = nil,
        topPadding: CGFloat = 10,
        bottomPadding: CGFloat = 2,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.systemImage = systemImage
        self.iconTint = iconTint
        self.detail = detail
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.trailing = trailing()
    }

    package var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .foregroundStyle(iconTint)
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
}

package extension ListSectionHeader where Trailing == EmptyView {

    init(
        _ title: String,
        systemImage: String? = nil,
        iconTint: Color = .secondary,
        detail: String? = nil,
        topPadding: CGFloat = 10,
        bottomPadding: CGFloat = 2
    ) {
        self.init(
            title,
            systemImage: systemImage,
            iconTint: iconTint,
            detail: detail,
            topPadding: topPadding,
            bottomPadding: bottomPadding
        ) {
            EmptyView()
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        ListSectionHeader("In progress")
        ListSectionHeader("Favorites", systemImage: "star.fill", iconTint: .yellow, detail: "3 devices", bottomPadding: 4)
        ListSectionHeader("Staged 2") {
            Button("Unstage All") {}
                .buttonStyle(LinkButtonStyle(.accent))
        }
    }
    .frame(width: 480)
    .background(Theme.surface)
}
