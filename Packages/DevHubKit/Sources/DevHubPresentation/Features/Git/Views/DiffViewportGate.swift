import SwiftUI

struct DiffViewportGate<Key: Equatable, Content: View>: View {
    @Environment(DiffViewport.self) private var viewport: DiffViewport?

    let id: String
    let key: Key
    let estimatedHeight: CGFloat
    let content: () -> Content

    @State private var measuredHeight: CGFloat?

    init(id: String, key: Key, estimatedHeight: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.id = id
        self.key = key
        self.estimatedHeight = estimatedHeight
        self.content = content
    }

    var body: some View {
        DiffViewportGateBody(
            key: key,
            isNear: viewport?.nearIDs.contains(id) ?? true,
            placeholderHeight: measuredHeight ?? estimatedHeight,
            content: content,
            onMeasure: { measuredHeight = $0 }
        )
        .equatable()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(DiffViewport.coordinateSpace)) } action: { viewport?.update(frame: $0, of: id) }
        .onChange(of: estimatedHeight) { measuredHeight = nil }
        .onDisappear { viewport?.forget(id) }
    }
}

private struct DiffViewportGateBody<Key: Equatable, Content: View>: View, Equatable {
    let key: Key
    let isNear: Bool
    let placeholderHeight: CGFloat
    let content: () -> Content
    let onMeasure: (CGFloat) -> Void

    var body: some View {
        if isNear {
            content()
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { onMeasure($0) }
        } else {
            Color.clear
                .frame(height: placeholderHeight)
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.isNear == rhs.isNear, lhs.key == rhs.key else { return false }
        return lhs.isNear || lhs.placeholderHeight == rhs.placeholderHeight
    }
}
