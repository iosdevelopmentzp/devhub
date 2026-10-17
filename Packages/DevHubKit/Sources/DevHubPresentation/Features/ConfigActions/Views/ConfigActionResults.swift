import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionResults: View {
    @Environment(ConfigActionsStore.self) private var store

    let placement: Placement
    let slot: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let pending = store.pending(in: slot) {
                ConfigActionPrompt(pending: pending)
            }
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
