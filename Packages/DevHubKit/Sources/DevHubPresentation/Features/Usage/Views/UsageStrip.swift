import SwiftUI
import DevHubDomain
import DevHubUI

struct UsageStrip: View {
    @Environment(UsageStore.self) private var store

    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        let summary = store.usage.map { UsageSummaryMapper.model(for: $0, now: .now) }
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Claude")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let summary {
                    ForEach(summary.meters) { meter in
                        UsageMeter(model: meter)
                            .hint(meter.resetText)
                    }
                    if let error = store.error {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .hint(error)
                    }
                } else if store.isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Loading Claude usage…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(store.error ?? "Claude usage unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Button("Retry", action: refresh)
                    .buttonStyle(LinkButtonStyle(.accent))
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
                UsageDetails(
                    summary: summary,
                    error: store.error,
                    isRefreshing: store.isRefreshing,
                    onRefresh: refresh
                )
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
