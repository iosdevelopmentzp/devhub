import SwiftUI
import DevHubDomain
import DevHubUI

struct AIWriteButton: View {
    let model: AIWriteButtonModel
    let onPick: (AIProvider) -> Void
    let onStop: () -> Void

    var body: some View {
        if model.isRunning {
            Button("Stop", systemImage: "stop.circle", action: onStop)
                .buttonStyle(LinkButtonStyle(.secondary, weight: .medium))
                .fixedSize()
                .hint(model.stopHint)
        } else {
            Menu {
                ForEach(model.choices) { choice in
                    Button(choice.title, systemImage: "sparkles") {
                        onPick(choice.id)
                    }
                }
            } label: {
                Label(model.title, systemImage: "sparkles")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            } primaryAction: {
                onPick(model.defaultProvider)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(model.isEnabled == false)
            .hint(model.hint)
        }
    }
}

#Preview {
    AIWriteButton(model: .preview, onPick: { _ in }, onStop: {})
        .padding()
        .previewEnvironment()
}
