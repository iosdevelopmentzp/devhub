import SwiftUI

package struct FieldLabel: View {
    package let text: String

    package init(_ text: String) {
        self.text = text
    }

    package var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 78, alignment: .leading)
    }
}

#Preview {
    HStack {
        FieldLabel("Device ID")
        Text("A1B2C3")
            .font(.caption.monospaced())
    }
    .padding(14)
}
