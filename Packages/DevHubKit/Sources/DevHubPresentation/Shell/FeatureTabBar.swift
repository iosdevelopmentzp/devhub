import SwiftUI
import DevHubDomain
import DevHubUI

struct FeatureTabBar: View {
    @Environment(OpenPullRequestsStore.self) private var openPullRequests
    @Environment(ConfigStore.self) private var config
    @Environment(\.codeHostWords) private var words

    @Binding var selection: TabID

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tabs(showsTitles: true)
            tabs(showsTitles: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func badge(for id: TabID) -> Int? {
        guard id == .feature(.pullRequests), openPullRequests.reviewCount > 0 else { return nil }
        return openPullRequests.reviewCount
    }

    private func tabs(showsTitles: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(TabItemMapper.items(customTabs: config.resolved.tabs, words: words).enumerated()), id: \.element.id) { index, item in
                TabButton(item: item, isSelected: item.id == selection, shortcutIndex: index + 1, showsTitle: showsTitles || item.id == selection, badge: badge(for: item.id)) {
                    selection = item.id
                }
            }
        }
    }
}
