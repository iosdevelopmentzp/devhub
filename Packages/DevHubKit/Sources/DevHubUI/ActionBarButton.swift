import SwiftUI

package struct ActionBarButton: View {
    package let item: ActionItem
    package let showsTitle: Bool

    package init(item: ActionItem, showsTitle: Bool) {
        self.item = item
        self.showsTitle = showsTitle
    }

    package var body: some View {
        Button(action: item.action) {
            if showsTitle {
                Label(item.title, systemImage: item.systemImage)
            } else {
                Label(item.title, systemImage: item.systemImage)
                    .labelStyle(.iconOnly)
            }
        }
        .tint(item.tint)
        .fixedSize()
        .disabled(item.isDisabled)
        .hint(showsTitle ? item.hint : "\(item.title)\n\(item.hint)")
    }
}
