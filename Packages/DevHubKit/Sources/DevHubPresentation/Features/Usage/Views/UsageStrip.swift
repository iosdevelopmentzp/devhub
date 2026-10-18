import SwiftUI
import DevHubDomain
import DevHubUI

struct UsageStrip: View {
    @Environment(UsageStore.self) private var store

    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        let providers = UsageProviderMapper.models(
            claude: store.usage,
            claudeError: store.error,
            copilot: store.copilot,
            copilotError: store.copilotError,
            now: .now
        )
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    ForEach(providers) { provider in
                        UsageProviderRow(model: provider, isRefreshing: store.isRefreshing, onRetry: refresh)
                    }
                }
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isHovered ? Theme.hover : .clear)
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }
            .onHover { isHovered = $0 }

            if isExpanded {
                UsageDetails(providers: providers, isRefreshing: store.isRefreshing, onRefresh: refresh)
            }
        }
        .animation(.snappy(duration: 0.18), value: isExpanded)
    }

    private func refresh() {
        Task { await store.refresh() }
    }
}

#Preview {
    VStack(spacing: 0) {
        UsageStrip()
        Divider()
        Spacer()
    }
    .previewEnvironment()
    .frame(width: 720, height: 200)
}
