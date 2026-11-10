import SwiftUI

struct DiffViewportModifier<Pinned: View>: ViewModifier {
    @State private var viewport = DiffViewport()

    let pinned: () -> Pinned

    init(@ViewBuilder pinned: @escaping () -> Pinned) {
        self.pinned = pinned
    }

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGRect.self, of: \.visibleRect) { _, visibleRect in
                viewport.update(visibleRect: visibleRect)
            }
            .overlay(alignment: .topLeading) {
                pinned()
            }
            .environment(viewport)
    }
}
