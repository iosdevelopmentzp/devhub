import SwiftUI
import DevHubUI

struct PipelineJobRow: View {
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster
    @Environment(\.codeHostWords) private var words

    let model: PipelineJobRowModel
    let onToggleLog: () -> Void
    let onRetry: () -> Void
    let onApprove: () -> Void
    let onToggleDetails: () -> Void
    let onToggleTestMessage: (_ testID: String) -> Void

    @State private var isConfirmingApprove = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: model.icon)
                    .font(.caption)
                    .foregroundStyle(model.tint.color)
                    .frame(width: 16)
                    .hint(model.statusText)
                Text(model.title)
                    .font(.caption)
                    .lineLimit(1)
                    .hintWhenTruncated(model.title)
                Text(model.statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let durationText = model.durationText {
                    Text(durationText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .hint("How long the \(words.job) ran")
                }
                if let allowedToFailText = model.allowedToFailText {
                    Tag(allowedToFailText, tint: .orange, systemImage: "exclamationmark.triangle")
                        .hint("A failure of this \(words.job) does not fail the \(words.checks)")
                }
                if let flakyTag = model.flakyTag {
                    ModelTag(model: flakyTag)
                }
                if let detailsTitle = model.detailsTitle {
                    detailsToggle(detailsTitle)
                }
                Spacer(minLength: 4)
                if model.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
                if model.canApprove {
                    IconButton(systemImage: "checkmark.seal", help: model.approveHint, tint: .green) {
                        isConfirmingApprove = true
                    }
                    .disabled(model.isBusy || isConfirmingApprove)
                }
                if model.canShowLog {
                    IconButton(systemImage: model.isLogOpen ? "doc.text.fill" : "doc.text", help: model.isLogOpen ? "Hide the log" : "Show the end of the log") {
                        onToggleLog()
                    }
                }
                if model.canRetry {
                    IconButton(systemImage: "arrow.clockwise", help: model.retryHint) {
                        onRetry()
                    }
                    .disabled(model.isBusy)
                }
                if model.url != nil {
                    IconButton(systemImage: "globe", help: "Open in \(words.name)") {
                        appActions.open(model.url)
                    }
                }
            }
            if isConfirmingApprove {
                InlineConfirmation(
                    "Approve \(model.title)? The jobs that wait for it start.",
                    confirmTitle: "Approve",
                    confirmRole: nil,
                    systemImage: "checkmark.seal",
                    tint: .green,
                    onCancel: { isConfirmingApprove = false },
                    onConfirm: {
                        isConfirmingApprove = false
                        onApprove()
                    }
                )
                .padding(.leading, 24)
            }
            if let noteText = model.noteText {
                Text(noteText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 24)
            }
            if model.isDetailsOpen {
                if let failureText = model.failureText {
                    Text(failureText)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 24)
                }
                ForEach(model.failedTests) { test in
                    FailedTestLine(model: test) {
                        onToggleTestMessage(test.id)
                    }
                    .padding(.leading, 24)
                }
            }
            if model.isLogOpen, let log = model.log {
                logView(log)
            }
        }
        .animation(.snappy(duration: 0.18), value: isConfirmingApprove)
        .animation(.snappy(duration: 0.18), value: model.isDetailsOpen)
    }

    private func detailsToggle(_ title: String) -> some View {
        Button(action: onToggleDetails) {
            HStack(spacing: 3) {
                Image(systemName: model.isDetailsOpen ? "chevron.down" : "chevron.right")
                    .font(.caption2.weight(.semibold))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .hint(model.detailsHint)
    }

    @ViewBuilder
    private func logView(_ log: JobLogState) -> some View {
        switch log {
        case .loading:
            ProgressView("Reading the log…")
                .controlSize(.small)
                .padding(.leading, 24)
        case .failure(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.leading, 24)
        case .loaded(let text):
            VStack(alignment: .trailing, spacing: 4) {
                ScrollView {
                    Text(text.isEmpty ? "The log is empty" : text)
                        .font(.system(size: 10, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
                .defaultScrollAnchor(.bottom)
                .frame(maxHeight: 240)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Button("Copy Log", systemImage: "doc.on.doc") {
                    toaster.copy(text, label: "Log")
                }
                .buttonStyle(LinkButtonStyle(.accent))
                .font(.caption)
            }
            .padding(.leading, 24)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        PipelineJobRow(model: .preview, onToggleLog: {}, onRetry: {}, onApprove: {}, onToggleDetails: {}, onToggleTestMessage: { _ in })
        PipelineJobRow(model: .previewCircleCI, onToggleLog: {}, onRetry: {}, onApprove: {}, onToggleDetails: {}, onToggleTestMessage: { _ in })
    }
    .previewEnvironment()
    .padding()
    .frame(width: 560)
}
