import SwiftUI

struct ConfigActionResults: View {
    @Environment(ActionCatalog.self) private var catalog
    @Environment(ActionRunner.self) private var runner

    let placement: Placement
    let slot: String
    let showsResults: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let pending = runner.pending(in: slot) {
                ActionPrompt(pending: pending)
            }
            if showsResults {
                ForEach(catalog.actions(for: placement)) { action in
                    ActionResultView(action: action)
                }
            }
        }
    }
}

#Preview {
    ConfigActionResults(placement: .gitPills, slot: "preview", showsResults: true)
        .padding()
        .previewEnvironment()
}
