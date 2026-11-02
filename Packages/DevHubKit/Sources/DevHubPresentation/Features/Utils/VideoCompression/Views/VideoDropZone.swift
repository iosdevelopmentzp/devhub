import SwiftUI
import DevHubDomain
import DevHubUI

struct VideoDropZone: View {
    let isTargeted: Bool
    let isCompact: Bool
    let onChoose: () -> Void

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: isCompact ? nil : .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isTargeted ? Color.accentColor.opacity(0.08) : Theme.base)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isTargeted ? Color.accentColor : Theme.border, style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [6, 4]))
            )
    }

    @ViewBuilder
    private var content: some View {
        if isCompact {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.doc")
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                Text("Drop more videos here, or")
                    .foregroundStyle(.secondary)
                Button("Choose Videos…", action: onChoose)
                    .buttonStyle(LinkButtonStyle(.accent, weight: .medium))
                Spacer(minLength: 0)
            }
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .hint("You can also drop videos on the DevHub icon in the menu bar while the panel is closed.")
        } else {
            VStack(spacing: 10) {
                Image(systemName: "film.stack")
                    .font(.system(size: 34))
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                Text(isTargeted ? "Drop to compress" : "Drop videos here")
                    .font(.title3.weight(.semibold))
                Text("DevHub compresses each video with ffmpeg and saves it next to the original as “<name> compressed.mp4”. The original stays.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
                Button("Choose Videos…", action: onChoose)
                    .fixedSize()
                Label("Panel closed? Drop videos on the DevHub icon in the menu bar.", systemImage: "menubar.arrow.up.rectangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(24)
        }
    }
}

#Preview {
    VideoDropZone(isTargeted: false, isCompact: false, onChoose: {})
        .frame(height: 320)
        .padding()
}
