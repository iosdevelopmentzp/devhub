import SwiftUI

struct FooterStatus: View {
    @Environment(CommandLog.self) private var commandLog
    @Environment(ActionRunner.self) private var runner
    @Environment(BuildStore.self) private var build

    private var running: CommandEntry? {
        commandLog.entries.first { $0.isRunning && $0.kind != .read }
    }

    private var lastFinished: CommandEntry? {
        commandLog.entries.first { $0.isRunning == false && $0.kind != .read }
    }

    var body: some View {
        HStack(spacing: 6) {
            if let text = build.statusText {
                ProgressView()
                    .controlSize(.mini)
                label(text)
            } else if let progress = runner.progress {
                progressIndicator(progress)
                label("\(progress.actionTitle): \(progress.text)")
            } else if let running {
                ProgressView()
                    .controlSize(.mini)
                label("Running \(running.command)")
            } else if let lastFinished, lastFinished.isFailure {
                StatusDot(color: .red)
                label("Failed: \(lastFinished.command)")
            } else {
                StatusDot(color: .green)
                label("Ready")
            }
        }
    }

    @ViewBuilder
    private func progressIndicator(_ progress: ActionProgress) -> some View {
        if let fraction = progress.fraction {
            ProgressView(value: fraction)
                .progressViewStyle(.linear)
                .frame(width: 60)
        } else {
            ProgressView()
                .controlSize(.mini)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .hintWhenTruncated(text)
    }
}

#Preview {
    FooterStatus()
        .padding()
        .previewEnvironment()
}
