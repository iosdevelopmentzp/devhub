import SwiftUI

struct OverflowMenu<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .hint("More actions")
    }
}

#Preview {
    OverflowMenu {
        Button("Copy", systemImage: "doc.on.doc") {}
    }
    .padding()
    .previewEnvironment()
}
