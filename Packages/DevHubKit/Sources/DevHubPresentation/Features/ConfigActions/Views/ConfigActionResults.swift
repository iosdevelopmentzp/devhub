import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionResults: View {
    @Environment(ConfigActionsStore.self) private var store

    let placement: Placement
    let slot: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ConfigActionPromptSlot(slot: slot)
            ForEach(store.actions(for: placement).compactMap(\.resolved)) { action in
                ConfigActionResultView(action: action)
            }
        }
    }
}

#Preview {
    ConfigActionResults(placement: .gitPills, slot: "preview")
        .padding()
        .previewEnvironment()
}
