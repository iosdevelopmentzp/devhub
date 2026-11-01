import SwiftUI
import DevHubDomain
import DevHubUI

struct CrashBanner: View {
    let model: CrashBannerModel
    let onToggle: () -> Void
    let onOpenReport: () -> Void
    let onFix: (AIProvider) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                    .foregroundStyle(Tint.red.color)
                Text(model.title)
                    .font(.caption.weight(.semibold))
                Text(model.timeText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                IconButton(systemImage: "xmark", help: "Hide this crash", action: onDismiss)
            }
            Text(model.detail)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(model.messages.enumerated()), id: \.offset) { _, message in
                Text(message)
                    .font(.caption2.monospaced())
                    .foregroundStyle(Tint.red.color)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.isOpen {
                frames
            }
            HStack(spacing: 12) {
                Button(model.toggleTitle, action: onToggle)
                    .buttonStyle(LinkButtonStyle(.accent, weight: .medium))
                    .fixedSize()
                Button("Open Report", action: onOpenReport)
                    .buttonStyle(LinkButtonStyle(.secondary))
                    .fixedSize()
                    .hint(model.reportPath)
                AIProviderMenu(title: "Fix with AI", systemImage: "sparkles", hint: "Writes the crash into a prompt file and starts the tool in the terminal, inside the build source", onPick: onFix)
                    .fixedSize()
            }
            .controlSize(.small)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tint.red.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Tint.red.color.opacity(0.25)))
    }

    private var frames: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(model.frames) { frame in
                HStack(spacing: 6) {
                    Text("\(frame.id)")
                        .foregroundStyle(.tertiary)
                        .frame(width: 18, alignment: .trailing)
                    Text(frame.text)
                        .fontWeight(frame.isApp ? .semibold : .regular)
                        .foregroundStyle(frame.isApp ? Color.primary : Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hintWhenTruncated(frame.text)
                    Spacer(minLength: 4)
                    if let place = frame.place {
                        Text(place)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption2.monospaced())
            }
            if model.hiddenFrameCount > 0 {
                Text(CountText.count(model.hiddenFrameCount, "more frame in the report", "more frames in the report"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

#Preview {
    CrashBanner(model: .preview, onToggle: {}, onOpenReport: {}, onFix: { _ in }, onDismiss: {})
        .padding()
        .frame(width: 560)
        .previewEnvironment()
}
