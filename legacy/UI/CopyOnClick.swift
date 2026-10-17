import SwiftUI

struct CopyOnClickModifier: ViewModifier {
    @Environment(Toaster.self) private var toaster: Toaster?

    let value: String
    let label: String

    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .underline(isHovering)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .onTapGesture { toaster?.copy(value, label: label) }
            .pointerStyle(.link)
            .modifier(TruncationHintModifier(text: value, extra: "Click to copy"))
    }
}

extension View {
    func copyOnClick(_ value: String, label: String) -> some View {
        modifier(CopyOnClickModifier(value: value, label: label))
    }
}
