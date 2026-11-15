import SwiftUI
import DevHubDomain
import DevHubUI

struct FeatureTabBar: View {
    @Environment(Navigator.self) private var navigator
    @Environment(OpenPullRequestsStore.self) private var openPullRequests
    @Environment(ConfigStore.self) private var config
    @Environment(\.codeHostWords) private var words

    @Binding var selection: TabID

    static let moveHint = "Drag to change the order. Right-click to move it to Utils."
    static let orderHint = "Drag to change the order."

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tabs(showsTitles: true)
            tabs(showsTitles: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var items: [TabItem] {
        TabItemMapper.items(in: .bar, layout: navigator.layout, customTabs: config.resolved.tabs, words: words)
    }

    private func badge(for id: TabID) -> Int? {
        guard id == .feature(.pullRequests), openPullRequests.reviewCount > 0 else { return nil }
        return openPullRequests.reviewCount
    }

    private func tabs(showsTitles: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                TabButton(
                    item: item,
                    isSelected: item.id == selection,
                    shortcutIndex: index + 1,
                    showsTitle: showsTitles || item.id == selection,
                    badge: badge(for: item.id),
                    hintDetail: navigator.canMove(item.id) ? Self.moveHint : Self.orderHint
                ) {
                    selection = item.id
                }
                .tabReordering(item.id, navigator: navigator)
                .tabPlacementMenu(for: item.id, isEnabled: navigator.canMove(item.id) || navigator.layout.hasCustomOrder)
            }
        }
    }
}
