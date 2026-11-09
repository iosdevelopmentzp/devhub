import SwiftUI

struct DiffViewportModifier: ViewModifier {
    @State private var viewport = DiffViewport()

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGRect.self, of: \.visibleRect) { _, visibleRect in
                viewport.update(visibleRect: visibleRect)
            }
            .environment(viewport)
    }
}
