import SwiftUI
import DevHubDomain
import DevHubUI

struct RootView: View {
    @Environment(Navigator.self) private var navigator
    @Environment(ProjectSession.self) private var session
    @Environment(SettingsStore.self) private var settings
    @Environment(Toaster.self) private var toaster
    @Environment(OutputPanelState.self) private var output
    @Environment(UsageStore.self) private var usage
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(BuildStore.self) private var build
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(ConfigStore.self) private var config
    @Environment(\.hintCenter) private var hintCenter
    @Environment(\.isPinnedWindow) private var isPinnedWindow
    @Environment(WindowLayout.self) private var layout

    var body: some View {
        @Bindable var navigator = navigator
        VStack(spacing: 0) {
            if settings.values.showUsageStrip {
                UsageStrip()
                Divider()
            }
            HeaderView()
            Divider()
            FeatureTabBar(selection: $navigator.selection)
            Divider()
            if session.hasProject {
                SearchFilterBar()
                featureView
            } else {
                NoProjectState()
            }
            if output.isVisible {
                Divider()
                OutputPanel()
            }
            Divider()
            FooterView()
        }
        .overlay {
            if let hintCenter {
                HintOverlay(center: hintCenter)
            }
        }
        .modifier(WindowFrame(layout: layout, isPinnedWindow: isPinnedWindow))
        .background(Theme.base)
        .clipShape(RoundedRectangle(cornerRadius: isPinnedWindow ? 0 : 10, style: .continuous))
        .background(WindowAppearance(name: .aqua))
        .colorScheme(.light)
        .task(id: layout.openCount) {
            usage.startPolling()
            async let usageRefresh: Void = usage.refreshIfStale()
            async let simulatorsRefresh: Void = simulators.refresh()
            guard session.hasProject else {
                _ = await (usageRefresh, simulatorsRefresh)
                return
            }
            async let schemesRefresh: Void = build.refreshSchemes()
            async let worktreesRefresh: Void = worktrees.refresh()
            async let configRefresh: Void = config.reload()
            _ = await (usageRefresh, simulatorsRefresh, schemesRefresh, worktreesRefresh, configRefresh)
        }
    }

    @ViewBuilder
    private var selectedView: some View {
        switch navigator.selection {
        case .feature(let id):
            FeatureRegistry.feature(id).makeView()
        case .custom(let id):
            if let tab = config.resolved.tabs.first(where: { $0.id == id }) {
                CustomTabView(tab: tab)
            } else {
                FeatureRegistry.feature(FeatureRegistry.defaultFeatureID).makeView()
            }
        }
    }

    private var featureView: some View {
        selectedView
                .id(navigator.selection)
                .environment(\.panelOpenCount, layout.openCount)
                .onChange(of: navigator.selection) { old, new in
                    session.switchSearch(from: old, to: new)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    if let toast = toaster.text {
                        ToastView(text: toast)
                            .padding(.bottom, 12)
                    }
                }
                .animation(.snappy(duration: 0.2), value: toaster.text)
    }
}

#Preview {
    RootView()
        .previewEnvironment()
}
