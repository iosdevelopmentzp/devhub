import SwiftUI

package struct ToolbarBar<Content: View>: View {
    private let verticalPadding: CGFloat
    private let controlSize: ControlSize
    private let content: Content

    package init(verticalPadding: CGFloat = 8, controlSize: ControlSize = .small, @ViewBuilder content: () -> Content) {
        self.verticalPadding = verticalPadding
        self.controlSize = controlSize
        self.content = content()
    }

    package var body: some View {
        content
            .controlSize(controlSize)
            .padding(.horizontal, 14)
            .padding(.vertical, verticalPadding)
            .background(Theme.base)
    }
}

#Preview {
    VStack(spacing: 0) {
        ToolbarBar {
            HStack(spacing: 8) {
                Text("7 worktrees")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Fetch", systemImage: "arrow.down.circle") {}
            }
        }
        Divider()
        Spacer()
    }
    .frame(width: 640, height: 160)
    .background(Theme.surface)
}
