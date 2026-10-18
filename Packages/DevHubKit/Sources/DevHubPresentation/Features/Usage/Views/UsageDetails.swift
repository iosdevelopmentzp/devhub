import SwiftUI
import DevHubDomain
import DevHubUI

struct UsageDetails: View {
    @Environment(AppActions.self) private var appActions

    let providers: [UsageProviderModel]
    let isRefreshing: Bool
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(providers) { provider in
                section(provider)
            }
            HStack(spacing: 8) {
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Button("Refresh", systemImage: "arrow.clockwise", action: onRefresh)
                        .buttonStyle(LinkButtonStyle(.secondary))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.surface)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func section(_ provider: UsageProviderModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(provider.title)
                    .font(.caption.weight(.semibold))
                if let summary = provider.summary {
                    ModelTag(model: summary.planTag)
                    Text(summary.updatedText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Open Usage", systemImage: "arrow.up.forward.square") {
                    appActions.open(provider.usageURL)
                }
                .buttonStyle(LinkButtonStyle(.secondary))
            }
            if let summary = provider.summary {
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
                if let note = summary.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let error = provider.error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}

#Preview {
    UsageDetails(providers: [.preview], isRefreshing: false, onRefresh: {})
        .previewEnvironment()
}
