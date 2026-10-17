import SwiftUI

package struct ActionBar: View {
    package let items: [ActionItem]

    package init(items: [ActionItem]) {
        self.items = items
    }

    package var body: some View {
        ActionBarLayout(priorities: items.map(\.priority), spacing: 6) {
            ForEach(items) { item in
                ActionBarButton(item: item, showsTitle: true)
                    .frame(minWidth: 0, minHeight: 0)
                    .clipped()
                ActionBarButton(item: item, showsTitle: false)
                    .frame(minWidth: 0, minHeight: 0)
                    .clipped()
            }
        }
    }
}
