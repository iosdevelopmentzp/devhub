import SwiftUI

struct ConfigActionMenuItems: View {
    @Environment(ActionCatalog.self) private var catalog
    @Environment(ActionRunner.self) private var runner

    let placement: Placement
    let slot: String
    let item: ActionItemContext

    var body: some View {
        ForEach(catalog.actions(for: placement)) { action in
            Button(action.title, systemImage: action.systemImage) {
                runner.request(action, item: item, slot: slot)
            }
            .disabled(action.isRunnable == false || runner.isRunning(action))
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
