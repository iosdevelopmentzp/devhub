import SwiftUI

struct FeatureTabBar: View {
    @Environment(Navigator.self) private var navigator

    var body: some View {
        ViewThatFits(in: .horizontal) {
            bar(titlesForAll: true)
            bar(titlesForAll: false)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .background(Theme.base)
        .background { shortcuts }
    }

    private func bar(titlesForAll: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(FeatureRegistry.all) { feature in
                FeatureTabButton(
                    feature: feature,
                    isSelected: feature.id == navigator.selectedID,
                    showsTitle: titlesForAll || feature.id == navigator.selectedID
                ) {
                    navigator.show(feature.id)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var shortcuts: some View {
        ForEach(Array(FeatureRegistry.all.prefix(9).enumerated()), id: \.element.id) { index, feature in
            Button(feature.title) { navigator.show(feature.id) }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    FeatureTabBar()
        .previewEnvironment()
}
