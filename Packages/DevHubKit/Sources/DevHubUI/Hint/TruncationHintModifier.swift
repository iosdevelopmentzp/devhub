import SwiftUI

package struct TruncationHintModifier: ViewModifier {
    package let fullText: String
    package let suffix: String?

    @State private var isHovered = false
    @State private var idealWidth: CGFloat = 0
    @State private var width: CGFloat = 0

    package init(fullText: String, suffix: String?) {
        self.fullText = fullText
        self.suffix = suffix
    }

    package func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .background {
                if isHovered {
                    content
                        .fixedSize()
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { idealWidth = $0 }
                }
            }
            .onHover { isHovered = $0 }
            .hint(hintText)
    }

    private var isTruncated: Bool {
        isHovered && idealWidth > width + 0.5
    }

    private var hintText: String? {
        if isTruncated {
            return [fullText, suffix].compactMap { $0 }.joined(separator: "\n")
        }
        return suffix
    }
}
