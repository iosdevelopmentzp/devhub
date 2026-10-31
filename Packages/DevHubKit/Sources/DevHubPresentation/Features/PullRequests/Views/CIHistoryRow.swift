import SwiftUI
import DevHubUI

struct CIHistoryRow: View {
    let model: CIHistoryRowModel
    let onToggle: () -> Void
    let onToggleTestMessage: (_ testID: String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Button(action: onToggle) {
                    Image(systemName: model.isOpen ? "chevron.down" : "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 12, height: 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(model.failedJobs.isEmpty)
                .hint(model.toggleHint)
                Text(model.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .hintWhenTruncated(model.title)
                ModelTag(model: model.statusTag)
                if let timeText = model.timeText {
                    Text(timeText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(model.summaryText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if model.isOpen {
                ForEach(model.failedJobs) { job in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(width: 16)
                            Text(job.title)
                                .font(.caption)
                                .lineLimit(1)
                                .hintWhenTruncated(job.title)
                        }
                        ForEach(job.tests) { test in
                            FailedTestLine(model: test) {
                                onToggleTestMessage(test.id)
                            }
                            .padding(.leading, 24)
                        }
                    }
                    .padding(.leading, 18)
                }
            }
        }
    }
}

#Preview {
    CIHistoryRow(model: .preview, onToggle: {}, onToggleTestMessage: { _ in })
        .padding()
        .frame(width: 560)
        .previewEnvironment()
}
