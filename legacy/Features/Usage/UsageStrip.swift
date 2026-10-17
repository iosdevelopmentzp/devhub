import SwiftUI

struct UsageStrip: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(UsageStore.self) private var store
    @Environment(WindowLayout.self) private var layout

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 0)
                .task(id: layout.openCount) {
                    guard settings.showUsageStrip else { return }
                    await store.refreshIfStale()
                }
            if settings.showUsageStrip, store.visibleProviders.isEmpty == false {
                ForEach(store.visibleProviders) { id in
                    UsageProviderRow(id: id)
                }
                Divider()
            }
        }
        .background(Theme.base)
    }
}

#Preview {
    UsageStrip()
        .previewEnvironment()
}
