import SwiftUI
import DevHubDomain
import DevHubUI

struct UtilsTabBar: View {
    @Environment(Navigator.self) private var navigator

    let items: [TabItem]
    let selection: TabID?
    let showsSearch: Bool
    let onSelect: (TabID) -> Void

    static let moveHint = "Right-click to show it in the tab bar."

    var body: some View {
        ToolbarBar(verticalPadding: 6) {
            HStack(spacing: 10) {
                ViewThatFits(in: .horizontal) {
                    tabs(showsTitles: true)
                    tabs(showsTitles: false)
                }
                Spacer(minLength: 0)
                if showsSearch {
                    TabSearchField()
                }
            }
        }
    }

    private func tabs(showsTitles: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                TabButton(
                    item: item,
                    isSelected: item.id == selection,
                    shortcutIndex: nil,
                    showsTitle: showsTitles || item.id == selection,
                    badge: nil,
                    hintDetail: navigator.canMove(item.id) ? Self.moveHint : nil,
                    action: { onSelect(item.id) },
                    stretches: false
                )
                .tabPlacementMenu(for: item.id, isEnabled: navigator.canMove(item.id))
            }
        }
    }
}

#Preview {
    UtilsTabBar(
        items: [TabItem(id: .utility(.compressVideo), title: "Compress Video", systemImage: "film", searchPrompt: "Filter videos"), TabItem(id: .custom("qa"), title: "QA", systemImage: "wrench", searchPrompt: "Search QA")],
        selection: .utility(.compressVideo),
        showsSearch: true
    ) { _ in }
    .previewEnvironment()
}
