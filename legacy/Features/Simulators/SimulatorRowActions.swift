import SwiftUI

struct SimulatorRowActions: View {
    @Environment(SimulatorsStore.self) private var store
    @Environment(BuildStore.self) private var build
    @Environment(LogsStore.self) private var logs
    @Environment(Navigator.self) private var navigator

    let simulator: SimulatorInfo
    let slot: String

    @Binding var showsSend: Bool

    var body: some View {
        HStack(spacing: 2) {
            IconButton(systemImage: "play.fill", help: "Launch the installed app with the saved options", tint: .green) {
                build.launch(on: simulator)
            }
            IconButton(systemImage: "paperplane", help: "Open a deep link or send a push notification") {
                showsSend.toggle()
            }
            .popover(isPresented: $showsSend, arrowEdge: .bottom) {
                SimulatorSendPopover(simulator: simulator)
            }
            IconButton(systemImage: "text.alignleft", help: simulator.isBooted ? "Stream the app log" : "Boot the simulator to stream its log") {
                logs.startStream(udid: simulator.id, name: simulator.name)
                navigator.show("logs")
            }
            .disabled(simulator.isBooted == false)
            IconButton(systemImage: "xmark.bin", help: "Remove all apps from this simulator", tint: .red) {
                Task { await store.removeApps(from: simulator) }
            }
            .disabled(simulator.appCount == 0)
            IconButton(systemImage: "power", help: simulator.isBooted ? "Shut down" : "Boot", tint: simulator.isBooted ? .red : .green) {
                Task { await store.togglePower(simulator) }
            }
            OverflowMenu { SimulatorRowMenu(simulator: simulator, slot: slot) }
        }
    }
}

#Preview {
    @Previewable @State var shows = false
    SimulatorRowActions(
        simulator: SimulatorInfo(id: "A", name: "iPhone 17", runtime: "iOS 26.0", state: .booted, appCount: 1, isFavorite: false),
        slot: "preview",
        showsSend: $shows
    )
    .previewEnvironment()
}
