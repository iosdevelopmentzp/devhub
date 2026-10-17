import SwiftUI

struct HintModifier: ViewModifier {
    @Environment(HintCenter.self) private var center: HintCenter?

    let text: String?

    @State private var owner = UUID()
    @State private var frame = CGRect.zero
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
                frame = newFrame
                center?.frameChanged(owner: owner, frame: newFrame)
            }
            .onHover { hovering in
                isHovering = hovering
                guard let text else { return }
                center?.hoverChanged(owner: owner, text: text, frame: frame, isHovering: hovering)
            }
            .onDisappear { center?.hide(owner: owner) }
    }
}

struct TruncationHintModifier: ViewModifier {
    let text: String
    let extra: String?

    @State private var idealWidth: CGFloat = 0
    @State private var actualWidth: CGFloat = 0

    private var isTruncated: Bool { idealWidth > actualWidth + 1 }

    private var hintText: String? {
        switch (isTruncated, extra) {
        case (true, let extra?): "\(text)\n\(extra)"
        case (true, nil): text
        case (false, let extra?): extra
        case (false, nil): nil
        }
    }

    func body(content: Content) -> some View {
        content
            .background {
                content
                    .fixedSize(horizontal: true, vertical: false)
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { idealWidth = $0 }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { actualWidth = $0 }
            .modifier(HintModifier(text: hintText))
    }
}

extension View {
    func hint(_ text: String) -> some View {
        modifier(HintModifier(text: text))
    }

    func hintWhenTruncated(_ text: String) -> some View {
        modifier(TruncationHintModifier(text: text, extra: nil))
    }
}
