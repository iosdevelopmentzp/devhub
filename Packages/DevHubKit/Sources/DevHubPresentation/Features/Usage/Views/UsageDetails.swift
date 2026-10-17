import SwiftUI
import DevHubDomain
import DevHubUI

struct UsageDetails: View {
    @Environment(AppActions.self) private var appActions

    let summary: UsageSummaryModel?
    let error: String?
    let isRefreshing: Bool
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let summary {
                ForEach(summary.meters) { meter in
                    HStack(spacing: 8) {
                        Text(meter.title)
                            .font(.caption)
                        Spacer()
                        Text(meter.resetText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(meter.percentText)
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(meter.levelTint?.color ?? .accentColor)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            HStack(spacing: 8) {
                if let summary {
                    ModelTag(model: summary.planTag)
                    Text(summary.updatedText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Button("Refresh", systemImage: "arrow.clockwise", action: onRefresh)
                        .buttonStyle(LinkButtonStyle(.secondary))
                }
                Button("Open Usage", systemImage: "arrow.up.forward.square") {
                    appActions.open(URL(string: "https://claude.ai/settings/usage"))
                }
                .buttonStyle(LinkButtonStyle(.secondary))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.surface)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

#Preview {
    UsageDetails(summary: .preview, error: nil, isRefreshing: false, onRefresh: {})
        .previewEnvironment()
}
