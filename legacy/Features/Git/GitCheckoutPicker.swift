import SwiftUI

struct GitCheckoutPicker: View {
    @Environment(GitStore.self) private var store

    private var selection: Binding<GitCheckout> {
        Binding(
            get: { store.currentCheckout ?? GitCheckout(path: store.checkoutPath, title: "Main checkout", isMain: true) },
            set: { store.selectCheckout($0.path) }
        )
    }

    var body: some View {
        SearchablePicker(
            title: "Checkout",
            selection: selection,
            items: store.checkouts,
            label: { $0.title },
            detail: { $0.isMain ? nil : URL(fileURLWithPath: $0.path).lastPathComponent }
        )
        .trigger { checkout in
            AnyView(
                HStack(spacing: 6) {
                    Image(systemName: checkout.isMain ? "folder" : "square.stack.3d.up")
                        .foregroundStyle(Tint.indigo.color)
                    Text(checkout.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.base, in: RoundedRectangle(cornerRadius: 6))
            )
        }
    }
}

#Preview {
    GitCheckoutPicker()
        .padding()
        .previewEnvironment()
}
