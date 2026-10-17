import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionBar: View {
    @Environment(ConfigActionsStore.self) private var store

    let placement: Placement
    let item: ActionItemContext

    var body: some View {
        let items = ConfigActionItemMapper.models(for: store.actions(for: placement), isRunning: store.isRunning)
        if items.isEmpty == false {
            VStack(alignment: .leading, spacing: 6) {
                ActionBar(items: items.map { $0.actionItem(priority: 1, onRun: run) })
                    .controlSize(.small)
                ConfigActionResults(placement: placement, slot: placement.slot)
            }
        }
    }

    private func run(_ id: String) {
        store.request(id: id, item: item, slot: placement.slot)
    }
}

#Preview {
    ConfigActionBar(placement: .simulatorsRunBar, item: .none)
        .padding()
        .previewEnvironment()
}
