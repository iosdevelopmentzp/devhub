import SwiftUI
import DevHubDomain
import DevHubUI

struct DiffLine: View {
    let model: DiffLineModel
    let isHighlighted: Bool
    let onOpen: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            number(model.oldNumber)
            number(model.newNumber)
            Text(model.text)
                .foregroundStyle(foreground)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 10)
        }
        .font(.system(size: 11, design: .monospaced))
        .padding(.horizontal, 8)
        .padding(.vertical, 0.5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .overlay(alignment: .leading) {
            if isHighlighted {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onOpen?()
        }
    }

    private func number(_ value: Int?) -> some View {
        Text(value.map(String.init) ?? "")
            .foregroundStyle(.tertiary)
            .frame(width: 34, alignment: .trailing)
    }

    private var foreground: Color {
        (model.tint?.color ?? .primary).opacity(model.foregroundOpacity)
    }

    private var background: Color {
        if isHighlighted {
            return Color.accentColor.opacity(0.18)
        }
        return model.tint?.color.opacity(model.backgroundOpacity) ?? .clear
    }
}

#Preview {
    DiffLine(model: .preview, isHighlighted: true, onOpen: nil)
}
