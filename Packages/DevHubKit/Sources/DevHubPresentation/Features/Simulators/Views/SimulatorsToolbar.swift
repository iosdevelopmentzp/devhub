import SwiftUI
import DevHubDomain
import DevHubUI

struct SimulatorsToolbar: View {
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(BuildStore.self) private var build

    @Binding var isConfirmingBulkRemove: Bool

    var body: some View {
        ToolbarBar {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(SimulatorsToolbarText.count(simulators: simulators.all))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if simulators.withApps.isEmpty == false {
                    Tag(CountText.invariant(simulators.withApps.count, "with apps"), tint: .blue, systemImage: "app.badge")
                }
                Spacer()
                TabSearchField()
                Button("Remove Apps from All…", systemImage: "xmark.app") {
                    isConfirmingBulkRemove = true
                }
                .disabled(simulators.withApps.isEmpty || build.isRunning || simulators.bulkUninstall != nil)
            }

            if isConfirmingBulkRemove {
                InlineConfirmation(
                    "Remove all installed apps from \(CountText.invariant(simulators.withApps.count, "simulators"))? Shut-down devices boot one by one and shut down again. Settings stay.",
                    confirmTitle: "Remove",
                    confirmRole: .destructive,
                    onCancel: { isConfirmingBulkRemove = false },
                    onConfirm: {
                        isConfirmingBulkRemove = false
                        simulators.removeAppsFromAll()
                    }
                )
            }
        }
    }
}
