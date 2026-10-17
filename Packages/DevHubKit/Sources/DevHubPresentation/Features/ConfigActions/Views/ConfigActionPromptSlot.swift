import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionPromptSlot: View {
    @Environment(ConfigActionsStore.self) private var store

    let slot: String

    var body: some View {
        if let pending = store.pending(in: slot) {
            ConfigActionPrompt(pending: pending)
        }
    }
}

#Preview {
    ConfigActionPromptSlot(slot: "preview")
        .padding()
        .previewEnvironment()
}
