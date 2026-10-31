import SwiftUI
import DevHubUI

struct CIHistoryRow: View {
    let model: CIHistoryRowModel

    @State private var isOpen = false
    @State private var expandedTestIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Button {
                    isOpen.toggle()
                } label: {
                    Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 12, height: 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(model.failedJobs.isEmpty)
                .hint(isOpen ? "Hide the failed jobs" : model.toggleHint)
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
            if isOpen {
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
                            FailedTestLine(model: test, isExpanded: expandedTestIDs.contains(test.id)) {
                                toggleMessage(of: test)
                            }
                            .padding(.leading, 24)
                        }
                    }
                    .padding(.leading, 18)
                }
            }
        }
        .animation(.snappy(duration: 0.18), value: isOpen)
        .animation(.snappy(duration: 0.18), value: expandedTestIDs)
    }

    private func toggleMessage(of test: PipelineJobRowModel.FailedTest) {
        if expandedTestIDs.contains(test.id) {
            expandedTestIDs.remove(test.id)
        } else {
            expandedTestIDs.insert(test.id)
        }
    }
}

#Preview {
    CIHistoryRow(model: .preview)
        .padding()
        .frame(width: 560)
        .previewEnvironment()
}
