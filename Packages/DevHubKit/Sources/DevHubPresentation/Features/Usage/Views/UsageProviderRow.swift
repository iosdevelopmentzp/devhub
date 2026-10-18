import SwiftUI
import DevHubDomain
import DevHubUI

struct UsageProviderRow: View {
    let model: UsageProviderModel
    let isRefreshing: Bool
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(model.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            if let summary = model.summary {
                ForEach(summary.meters) { meter in
                    UsageMeter(model: meter)
                        .hint(meter.resetText)
                }
                if let note = summary.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                if let error = model.error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .hint(error)
                }
            } else if isRefreshing {
                ProgressView()
                    .controlSize(.mini)
                Text(model.loadingText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(model.error ?? model.unavailableText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .hintWhenTruncated(model.error ?? model.unavailableText)
                Spacer()
                Button("Retry", action: onRetry)
                    .buttonStyle(LinkButtonStyle(.accent))
            }
        }
    }
}

#Preview {
    UsageProviderRow(model: .preview, isRefreshing: false, onRetry: {})
        .padding()
        .frame(width: 600)
}
