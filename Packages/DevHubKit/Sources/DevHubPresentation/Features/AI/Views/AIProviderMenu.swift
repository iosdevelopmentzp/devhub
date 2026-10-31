import SwiftUI
import DevHubDomain
import DevHubUI

struct AIProviderMenu: View {
    let title: String
    let systemImage: String
    let hint: String
    let onPick: (AIProvider) -> Void

    var body: some View {
        Menu {
            ForEach(AIProvider.allCases, id: \.self) { provider in
                Button(AISessionRowMapper.toolTitle(for: provider), systemImage: "sparkles") {
                    onPick(provider)
                }
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.accentColor)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .hint(hint)
    }
}

#Preview {
    AIProviderMenu(title: "Fix with AI", systemImage: "sparkles", hint: "Writes a prompt file and runs the tool in the terminal") { _ in }
        .padding()
        .previewEnvironment()
}
