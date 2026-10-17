import SwiftUI
import DevHubDomain
import DevHubUI

struct FeatureTabBar: View {
    @Environment(OpenMergeRequestsStore.self) private var openMergeRequests

    @Binding var selection: FeatureID

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tabs(showsTitles: true)
            tabs(showsTitles: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func badge(for id: FeatureID) -> Int? {
        guard id == .gitlab, openMergeRequests.reviewCount > 0 else { return nil }
        return openMergeRequests.reviewCount
    }

    private func tabs(showsTitles: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(FeatureRegistry.tabBarFeatures.enumerated()), id: \.element.id) { index, feature in
                TabButton(feature: feature, isSelected: feature.id == selection, shortcutIndex: index + 1, showsTitle: showsTitles || feature.id == selection, badge: badge(for: feature.id)) {
                    selection = feature.id
                }
            }
        }
    }
}
