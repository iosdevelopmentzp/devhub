import SwiftUI
import DevHubDomain
import DevHubUI

struct VideoEngineCard: View {
    let model: VideoEngineModel
    let onInstall: () -> Void
    let onGetHomebrew: () -> Void
    let onCheckAgain: () -> Void

    var body: some View {
        HStack(alignment: model.isCompact ? .center : .top, spacing: 10) {
            icon
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.callout.weight(.semibold))
                if model.detail.isEmpty == false {
                    Text(model.detail)
                        .font(model.isCompact ? .caption.monospaced() : .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let command = model.command {
                    Text(command)
                        .font(.caption.monospaced())
                        .copyOnClick(command, label: "command")
                }
            }
            Spacer(minLength: 8)
            actions
        }
        .padding(model.isCompact ? 8 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(model.tint.color.opacity(0.08))
        )
    }

    @ViewBuilder
    private var icon: some View {
        if model.isWorking {
            ProgressView()
                .controlSize(.small)
        } else {
            Image(systemName: model.icon)
                .foregroundStyle(model.tint.color)
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch model.action {
        case .install(let title):
            Button(title, systemImage: "arrow.down.circle", action: onInstall)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .fixedSize()
                .hint("Runs brew install ffmpeg. Every line shows in the Output panel.")
        case .getHomebrew:
            HStack(spacing: 6) {
                Button("Get Homebrew", systemImage: "safari", action: onGetHomebrew)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .fixedSize()
                    .hint("Opens the Homebrew releases page on GitHub. Download the .pkg file and open it.")
                checkAgain
            }
        case .checkAgain:
            checkAgain
        case nil:
            EmptyView()
        }
    }

    private var checkAgain: some View {
        Button("Check Again", action: onCheckAgain)
            .controlSize(.small)
            .fixedSize()
            .hint("Looks for ffmpeg, ffprobe and libx264 again")
    }
}

#Preview {
    VideoEngineCard(model: .preview, onInstall: {}, onGetHomebrew: {}, onCheckAgain: {})
        .padding()
        .previewEnvironment()
}
