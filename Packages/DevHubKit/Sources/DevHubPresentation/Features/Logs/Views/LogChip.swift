import SwiftUI
import DevHubDomain
import DevHubUI

struct LogChip: View {
    let model: LogChipModel
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: model.dotTint.color)
            Text(model.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
            IconButton(systemImage: "xmark", help: "Close the stream", action: onClose)
                .controlSize(.mini)
        }
        .padding(.leading, 10)
        .padding(.trailing, 2)
        .padding(.vertical, 2)
        .background(model.isSelected ? Color.accentColor.opacity(0.14) : Theme.hover, in: Capsule())
        .overlay(Capsule().stroke(model.isSelected ? Color.accentColor.opacity(0.5) : .clear, lineWidth: 1))
        .contentShape(Capsule())
        .onTapGesture(perform: onSelect)
        .fixedSize()
    }
}

#Preview {
    LogChip(model: .preview, onSelect: {}, onClose: {})
        .padding()
}
