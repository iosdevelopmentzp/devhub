import SwiftUI

package struct HoverHitTestGate<Content: View>: View {
    private let content: Content

    @State private var isHovered = false

    package init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    package var body: some View {
        content
            .allowsHitTesting(isHovered)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(0..<3) { index in
            HoverHitTestGate {
                HStack {
                    Text("Row \(index)")
                    Spacer()
                    IconButton(systemImage: "trash", help: "Delete") {}
                }
                .padding(8)
            }
        }
    }
    .frame(width: 320)
}
