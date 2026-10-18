import SwiftUI
import DevHubDomain
import DevHubUI

struct LogChipsBar: View {
    @Environment(LogsStore.self) private var logs
    @Environment(SimulatorsStore.self) private var simulators

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(chips) { chip in
                LogChip(
                    model: chip,
                    onSelect: { logs.selectedID = chip.id },
                    onClose: { logs.remove(chip.id) }
                )
            }
            addMenu
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.base)
    }

    private var chips: [LogChipModel] {
        LogChipMapper.models(streams: logs.streams, selectedID: logs.selected?.id, simulators: simulators.all)
    }

    private var addMenu: some View {
        let options = LogChipMapper.addOptions(available: logs.availableSimulators, runtime: simulators.runtime(for:))
        return Menu {
            ForEach(options) { option in
                Button(option.title) {
                    logs.stream(on: option.id)
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
                .frame(width: 26, height: 22)
                .background(Theme.hover, in: Capsule())
                .contentShape(Capsule())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(options.isEmpty)
        .hint(options.isEmpty ? "No booted simulator left. Boot one first." : "Stream the logs of another booted simulator")
    }
}

#Preview {
    LogChipsBar()
        .previewEnvironment()
}
