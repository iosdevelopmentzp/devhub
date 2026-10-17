import SwiftUI

struct RootView: View {
    @Environment(\.panelActions) private var actions
    @Environment(Navigator.self) private var navigator
    @Environment(ProjectSession.self) private var session
    @Environment(WindowLayout.self) private var layout
    @Environment(OutputPanelState.self) private var output

    var body: some View {
        VStack(spacing: 0) {
            UsageStrip()
            HeaderView()
            FeatureTabBar()
            Divider()
            SearchFilterBar()
            content
            if output.isVisible {
                Divider()
                OutputPanel()
                    .frame(height: 220)
            }
            Divider()
            FooterView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.base)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
        .overlay { HintOverlay() }
        .overlay(alignment: .bottom) { ToastOverlay() }
        .background(WindowAppearance(name: .aqua))
        .colorScheme(.light)
        .task(id: layout.openCount) { await session.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        if let feature = FeatureRegistry.feature(id: navigator.selectedID) {
            feature.content()
                .id("\(feature.id)#\(layout.openCount)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EmptyState(systemImage: "questionmark.circle", title: "Unknown tab", text: "Pick a tab from the bar above.")
        }
    }
}

#Preview {
    RootView()
        .previewEnvironment()
}
