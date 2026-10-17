import SwiftUI

struct InlineError: View {
    let text: String
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Tint.red.color)
            Text(text)
                .font(.callout)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Retry", action: retry)
                .controlSize(.small)
        }
        .padding(10)
        .background(Tint.red.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .padding(14)
    }
}

#Preview {
    InlineError(text: "Something failed.") {}
}
