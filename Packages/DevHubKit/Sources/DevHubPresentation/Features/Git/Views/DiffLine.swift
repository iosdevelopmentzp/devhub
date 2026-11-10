import SwiftUI
import DevHubDomain
import DevHubUI

struct DiffLine: View {
    @Environment(\.diffFontSize) private var fontSize

    let model: DiffLineModel
    let side: DiffSide?
    let isHighlighted: Bool
    let onOpen: (() -> Void)?
    let onOpenOnWeb: (() -> Void)?
    let onComment: (() -> Void)?

    @State private var isHovered = false

    private static let numberWidthPerPoint: CGFloat = 3.1

    init(model: DiffLineModel, side: DiffSide? = nil, isHighlighted: Bool, onOpen: (() -> Void)?, onOpenOnWeb: (() -> Void)?, onComment: (() -> Void)?) {
        self.model = model
        self.side = side
        self.isHighlighted = isHighlighted
        self.onOpen = onOpen
        self.onOpenOnWeb = onOpenOnWeb
        self.onComment = onComment
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if side != .new {
                number(model.oldNumber)
            }
            if side != .old {
                number(model.newNumber)
            }
            Text(emphasizedText)
                .foregroundStyle(foreground)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 10)
        }
        .font(.system(size: fontSize, design: .monospaced))
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
        .overlay(alignment: .trailing) {
            if let onComment, isHovered {
                IconButton(systemImage: "plus.bubble", help: "Comment on this line") {
                    onComment()
                }
                .padding(.trailing, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onOpen?()
        }
        .onHover { isHovered = $0 }
        .contextMenu {
            if let onComment {
                Button("Comment on This Line…", systemImage: "plus.bubble", action: onComment)
            }
            if let onOpenOnWeb {
                Button("Open in Browser at This Line", systemImage: "safari", action: onOpenOnWeb)
            }
        }
    }

    private func number(_ value: Int?) -> some View {
        Text(value.map(String.init) ?? "")
            .foregroundStyle(.tertiary)
            .frame(width: (fontSize * Self.numberWidthPerPoint).rounded(.up), alignment: .trailing)
    }

    private var emphasizedText: AttributedString {
        var text = AttributedString(model.text)
        if let tint = model.tint {
            mark(model.emphasis, with: tint.color.opacity(0.28), in: &text)
        }
        mark(model.findRanges, with: Tint.yellow.color.opacity(0.5), in: &text)
        if let current = model.currentFindRange {
            mark([current], with: Tint.orange.color.opacity(0.7), in: &text)
        }
        return text
    }

    private func mark(_ ranges: [Range<Int>], with color: Color, in text: inout AttributedString) {
        for range in ranges {
            guard range.upperBound <= text.characters.count else { continue }
            let start = text.index(text.startIndex, offsetByCharacters: range.lowerBound)
            let end = text.index(text.startIndex, offsetByCharacters: range.upperBound)
            text[start..<end].backgroundColor = color
        }
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
    DiffLine(model: .preview, isHighlighted: true, onOpen: nil, onOpenOnWeb: nil, onComment: {})
}
