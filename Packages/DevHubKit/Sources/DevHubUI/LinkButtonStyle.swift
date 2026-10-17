import SwiftUI

package struct LinkButtonStyle: PrimitiveButtonStyle {
    package enum Tone {
        case secondary
        case accent
    }

    private let tone: Tone
    private let weight: Font.Weight?

    package init(_ tone: Tone, weight: Font.Weight? = nil) {
        self.tone = tone
        self.weight = weight
    }

    package func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(.plain)
            .font(font)
            .foregroundStyle(color)
    }

    private var font: Font {
        guard let weight else { return .caption }
        return .caption.weight(weight)
    }

    private var color: Color {
        switch tone {
        case .secondary: .secondary
        case .accent: .accentColor
        }
    }
}

#Preview {
    HStack(spacing: 14) {
        Button("Clear") {}
            .buttonStyle(LinkButtonStyle(.secondary))
        Button("Retry") {}
            .buttonStyle(LinkButtonStyle(.accent))
        Button("Clear search") {}
            .buttonStyle(LinkButtonStyle(.accent, weight: .medium))
        Button("Show log", systemImage: "doc.text") {}
            .buttonStyle(LinkButtonStyle(.secondary))
            .disabled(true)
    }
    .padding(14)
}
