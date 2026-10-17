import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionMenuItems: View {
    @Environment(ConfigActionsStore.self) private var store

    let placement: Placement
    let slot: String
    let item: ActionItemContext

    var body: some View {
        let actions = store.actions(for: placement).compactMap(\.resolved)
        if actions.isEmpty == false {
            Divider()
            ForEach(actions) { action in
                let model = ConfigActionItemMapper.model(for: action, isRunning: store.isRunning(action.id))
                Button(model.title, systemImage: model.systemImage) {
                    store.request(action, item: item, slot: slot)
                }
                .disabled(model.isEnabled == false)
            }
        }
    }
}

#Preview {
    Menu("Actions") {
        ConfigActionMenuItems(placement: .gitBranchRow, slot: "preview", item: .none)
    }
    .padding()
    .previewEnvironment()
}
