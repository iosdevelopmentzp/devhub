import SwiftUI

struct PanelCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: Theme.shadow, radius: 3, y: 1)
    }
}

#Preview {
    PanelCard { Text("Card") }
        .padding()
}
