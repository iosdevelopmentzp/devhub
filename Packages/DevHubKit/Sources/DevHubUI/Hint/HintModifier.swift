import SwiftUI

package struct HintModifier: ViewModifier {
    @Environment(\.hintCenter) private var center

    package let text: String?

    @State private var id = UUID()
    @State private var target = HintTarget()
    @State private var pending: Task<Void, Never>?

    package init(text: String?) {
        self.text = text
    }

    package func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { target.frame = $0 }
            .onChange(of: text, initial: true) { _, newText in
                target.text = newText
            }
            .onHover { hovering in
                pending?.cancel()
                guard let center else { return }
                guard hovering else {
                    center.hide(id: id)
                    return
                }
                let delay = center.delay
                pending = Task {
                    try? await Task.sleep(for: delay)
                    guard Task.isCancelled == false, let text = target.text, text.isEmpty == false else { return }
                    center.show(Hint(id: id, text: text, frame: target.frame))
                }
            }
            .onDisappear {
                pending?.cancel()
                center?.hide(id: id)
            }
    }
}

private final class HintTarget {
    var frame: CGRect = .zero
    var text: String?
}
