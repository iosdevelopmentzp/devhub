import SwiftUI
import DevHubDomain
import DevHubUI

struct NetworkToolbar: View {
    @Environment(NetworkStore.self) private var network
    @Environment(SimulatorsStore.self) private var simulators

    let shownCount: Int

    var body: some View {
        ToolbarBar {
            content
        }
    }

    private var content: some View {
        @Bindable var network = network
        let model = model
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("Simulator", selection: Binding(get: { network.selectedUDID }, set: { network.select($0) })) {
                    Text("Choose a booted simulator").tag(Simulator.ID?.none)
                    ForEach(model.simulators) { option in
                        Text(option.title).tag(Simulator.ID?.some(option.id))
                    }
                }
                .labelsHidden()
                .fixedSize()
                .hint("Only booted simulators are listed")
                Spacer(minLength: 0)
                TabSearchField()
            }
            HStack(spacing: 8) {
                Picker("Filter", selection: $network.filter) {
                    ForEach(model.filters) { option in
                        Text(option.title).tag(option.id)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .hint("Failed: status 400 or more, or an error. Slow: longer than 1 s.")
                Text(model.countText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                Spacer()
                Toggle(isOn: $network.isPaused) {
                    Label(model.pauseTitle, systemImage: "pause.fill")
                }
                .toggleStyle(.button)
                .fixedSize()
                .hint("Freeze the list to read it. New requests wait and appear when you resume.")
                IconButton(systemImage: "trash", help: "Clear the list") {
                    network.clear()
                }
                .disabled(model.canClear == false)
            }
            ConfigActionBar(placement: .networkToolbar, item: ActionItemContext(simulatorUDID: network.selectedUDID, simulatorName: network.selectedUDID.flatMap(simulators.simulator(id:))?.name))
        }
    }

    private var model: NetworkToolbarModel {
        NetworkToolbarMapper.model(
            simulators: simulators.all.filter { $0.isPhysical == false },
            runtime: simulators.runtime(for:),
            isPaused: network.isPaused,
            pendingCount: network.pendingCount,
            shownCount: shownCount,
            totalCount: network.allRequests.count
        )
    }
}

#Preview {
    NetworkToolbar(shownCount: 0)
        .previewEnvironment()
}
