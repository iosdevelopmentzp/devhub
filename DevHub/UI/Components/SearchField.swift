import SwiftUI

struct SearchField: View {
    let prompt: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    let onEscape: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(.callout)
                .focused(focus)
                .onKeyPress(.escape) {
                    onEscape()
                    return .handled
                }
            if text.isEmpty == false {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .hint("Clear search")
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool
    SearchField(prompt: "Search", text: $text, focus: $focused) {}
        .padding()
        .previewEnvironment()
}
