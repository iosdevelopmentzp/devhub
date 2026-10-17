import SwiftUI

package struct ToastView: View {
    package let text: String

    package init(text: String) {
        self.text = text
    }

    package var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.black.opacity(0.8)))
            .shadow(color: Theme.shadow, radius: 6, y: 2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
