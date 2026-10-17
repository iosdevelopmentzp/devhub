import SwiftUI

package struct OverflowMenu<Items: View>: View {
    package let items: Items

    package init(@ViewBuilder items: () -> Items) {
        self.items = items()
    }

    package var body: some View {
        Menu {
            items
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .frame(width: 24, height: 24)
        .hint("More actions")
    }
}
