import SwiftUI

struct ToastOverlay: View {
    @Environment(Toaster.self) private var toaster

    var body: some View {
        ZStack {
            if let toast = toaster.current {
                HStack(spacing: 6) {
                    Image(systemName: toast.tint == .red ? "xmark.octagon.fill" : "checkmark.circle.fill")
                        .foregroundStyle(toast.tint.color)
                    Text(toast.text)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.bubble, in: Capsule())
                .padding(.bottom, 44)
                .padding(.horizontal, 14)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.snappy(duration: 0.18), value: toaster.current)
        .allowsHitTesting(false)
    }
}

#Preview {
    ToastOverlay()
        .previewEnvironment()
}
