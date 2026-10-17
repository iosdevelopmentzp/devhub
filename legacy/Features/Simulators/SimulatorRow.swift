import SwiftUI

struct SimulatorRow: View {
    @Environment(SimulatorsStore.self) private var store
    @Environment(BuildStore.self) private var build

    let simulator: SimulatorInfo

    @State private var isHovered = false
    @State private var showsSend = false

    private var isTarget: Bool { store.targetID == simulator.id }

    private var slot: String { "simulators.row:\(simulator.id)" }

    private var showsActions: Bool { isHovered || isTarget || showsSend }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                StatusDot(color: simulator.isBooted ? .green : .gray)
                IconTile(systemImage: simulator.symbol, tint: isTarget ? .blue : .gray)
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            if store.confirmation == .erase(simulator.id) {
                InlineConfirm(
                    text: "Erase \(simulator.name)? All apps, data and settings on it are deleted.",
                    confirmTitle: "Erase",
                    tint: .red,
                    onCancel: { store.setConfirmation(nil) },
                    onConfirm: { Task { await store.erase(simulator) } }
                )
            }
            ConfigActionResults(placement: .simulatorsRow, slot: slot, showsResults: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isTarget ? Color.accentColor.opacity(0.07) : (isHovered ? Theme.hover : .clear))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu { SimulatorRowMenu(simulator: simulator, slot: slot) }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(simulator.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .copyOnClick(simulator.id, label: "UDID")
                Tag(simulator.runtime, tint: .gray)
                if isTarget {
                    Tag("target", tint: .blue)
                }
                favoriteStar
            }
            Text("\(simulator.isBooted ? "Booted" : "Shutdown") · \(simulator.appCountText)")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let status = store.statuses[simulator.id] {
                Text(status.text)
                    .font(.caption)
                    .foregroundStyle(status.isFailure ? Tint.red.color : Tint.indigo.color)
                    .lineLimit(1)
                    .hintWhenTruncated(status.text)
            }
        }
    }

    @ViewBuilder
    private var favoriteStar: some View {
        if simulator.isFavorite || isHovered {
            Button {
                store.toggleFavorite(simulator.id)
            } label: {
                Image(systemName: simulator.isFavorite ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundStyle(simulator.isFavorite ? Tint.yellow.color : Color.secondary)
            }
            .buttonStyle(.plain)
            .hint(simulator.isFavorite ? "Remove from favorites" : "Add to favorites")
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if let title = store.busy[simulator.id] {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView()
                .controlSize(.small)
        } else {
            SimulatorRowActions(simulator: simulator, slot: slot, showsSend: $showsSend)
                .opacity(showsActions ? 1 : 0)
        }
    }
}

#Preview {
    SimulatorRow(simulator: SimulatorInfo(id: "A", name: "iPhone 17", runtime: "iOS 26.0", state: .booted, appCount: 1, isFavorite: true))
        .previewEnvironment()
}
