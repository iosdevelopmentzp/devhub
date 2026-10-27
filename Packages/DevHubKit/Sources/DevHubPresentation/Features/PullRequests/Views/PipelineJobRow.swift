import SwiftUI
import DevHubUI

struct PipelineJobRow: View {
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster
    @Environment(\.codeHostWords) private var words

    let model: PipelineJobRowModel
    let onToggleLog: () -> Void
    let onRetry: () -> Void

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
                Spacer(minLength: 4)
                if model.isBusy {
                    ProgressView()
                        .controlSize(.small)
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
            if model.isLogOpen, let log = model.log {
                logView(log)
            }
        }
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
    PipelineJobRow(model: .preview, onToggleLog: {}, onRetry: {})
        .previewEnvironment()
        .padding()
        .frame(width: 560)
}
