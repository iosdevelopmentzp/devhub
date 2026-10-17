import SwiftUI

package struct HintBubble: View {
    package let text: String

    package init(text: String) {
        self.text = text
    }

    package var body: some View {
        CappedWidthLayout(maxWidth: 260) {
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.black.opacity(0.82)))
        .shadow(color: Theme.shadow, radius: 3, y: 1)
    }
}
