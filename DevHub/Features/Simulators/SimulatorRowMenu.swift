import SwiftUI

struct SimulatorRowMenu: View {
    @Environment(SimulatorsStore.self) private var store
    @Environment(BuildStore.self) private var build
    @Environment(Toaster.self) private var toaster

    let simulator: SimulatorInfo
    let slot: String

    private var item: ActionItemContext {
        ActionItemContext(simulatorUDID: simulator.id, simulatorName: simulator.name, rowID: simulator.id)
    }

    var body: some View {
        Button("Open in Simulator.app", systemImage: "macwindow") {
            Task { await store.showInSimulatorApp(simulator) }
        }
        Button("Make target", systemImage: "scope") { store.setTarget(simulator.id) }
            .disabled(store.targetID == simulator.id)
        Button("Copy UDID", systemImage: "doc.on.doc") { toaster.copy(simulator.id, label: "UDID") }
        Divider()
        if let bundleID = build.bundleID {
            Button("Uninstall \(bundleID)", systemImage: "trash") {
                Task { await store.uninstall(bundleID: bundleID, from: simulator) }
            }
            Button("Open data container", systemImage: "folder") {
                Task { await store.openDataContainer(bundleID: bundleID, of: simulator) }
            }
        }
        ConfigActionMenuItems(placement: .simulatorsRow, slot: slot, item: item)
        Divider()
        Button("Erase…", systemImage: "eraser", role: .destructive) { store.setConfirmation(.erase(simulator.id)) }
    }
}

#Preview {
    Menu("Menu") {
        SimulatorRowMenu(simulator: SimulatorInfo(id: "A", name: "iPhone 17", runtime: "iOS 26.0", state: .booted, appCount: 1, isFavorite: false), slot: "preview")
    }
    .previewEnvironment()
}
