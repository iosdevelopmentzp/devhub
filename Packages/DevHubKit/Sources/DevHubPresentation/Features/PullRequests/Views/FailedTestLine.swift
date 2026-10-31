import SwiftUI
import DevHubUI

struct FailedTestLine: View {
    let model: PipelineJobRowModel.FailedTest
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.red)
                Text(model.title)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .hintWhenTruncated(model.title)
                    .copyOnClick(model.title, label: "Test name")
                if let flakyText = model.flakyText {
                    Tag(flakyText, tint: .orange, systemImage: "shuffle")
                        .hint("This test is in the flaky list of CircleCI Insights: it failed and then passed on a re-run")
                }
                if model.message != nil {
                    Button(action: onToggle) {
                        Image(systemName: model.isMessageOpen ? "chevron.down" : "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 12, height: 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .hint(model.isMessageOpen ? "Hide the message" : "Show the message")
                }
            }
            if model.isMessageOpen, let message = model.message {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 16)
            }
        }
    }
}

#Preview {
    FailedTestLine(model: PipelineJobRowModel.previewCircleCI.failedTests[0], onToggle: {})
        .padding()
        .frame(width: 480)
}
