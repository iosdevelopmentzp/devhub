import SwiftUI

struct RunBarCard: View {
    @Environment(BuildStore.self) private var build
    @Environment(ActionCatalog.self) private var catalog
    @Environment(ActionRunner.self) private var runner

    static let slot = "simulators.runBar"

    var body: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 10) {
                RunBarOptions()
                Divider()
                RunBarTarget()
                RunBarButtons()
                if build.profiles.isEmpty == false {
                    RunBarProfile()
                }
                Text(build.infoLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if build.phase != .idle || build.attachNotice != nil {
                    RunBarResult()
                }
                if catalog.actions(for: .simulatorsRunBar).isEmpty == false || runner.pending(in: Self.slot) != nil {
                    ConfigActionResults(placement: .simulatorsRunBar, slot: Self.slot, showsResults: true)
                }
            }
        }
    }
}

#Preview {
    RunBarCard()
        .padding()
        .previewEnvironment()
}
