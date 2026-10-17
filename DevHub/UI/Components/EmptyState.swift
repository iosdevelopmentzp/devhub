import SwiftUI

struct EmptyState: View {
    let systemImage: String
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.headline)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyState(systemImage: "checkmark.circle", title: "Nothing here", text: "This screen arrives in a later step.")
}
