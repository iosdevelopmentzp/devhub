import SwiftUI

struct InlineConfirm: View {
    let text: String
    let confirmTitle: String
    let tint: Tint
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Cancel", action: onCancel)
                .controlSize(.small)
            Button(confirmTitle, action: onConfirm)
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .tint(tint.color)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(8)
        .background(tint.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    InlineConfirm(text: "Delete this item?", confirmTitle: "Delete", tint: .red, onCancel: {}, onConfirm: {})
        .padding()
}
