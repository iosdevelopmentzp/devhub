import SwiftUI

struct LogChipsBar: View {
    @Environment(LogsStore.self) private var store

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(store.streams) { stream in
                LogChip(
                    stream: stream,
                    isSelected: stream.id == store.selected?.id,
                    isBooted: store.isBooted(stream.id),
                    select: { store.selectedID = stream.id },
                    close: { store.remove(stream.id) }
                )
            }
            addButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.base)
    }

    @ViewBuilder
    private var addButton: some View {
        let items = store.availableSimulators
        if let first = items.first {
            SearchablePicker(
                title: "Booted simulators",
                selection: Binding(get: { first }, set: { store.startStream(udid: $0.id, name: $0.name) }),
                items: items,
                label: { $0.name },
                detail: { $0.runtime }
            )
            .trigger { _ in
                AnyView(plusLabel(isEnabled: true))
            }
        } else {
            plusLabel(isEnabled: false)
                .hint("No booted simulator left. Boot one first.")
        }
    }

    private func plusLabel(isEnabled: Bool) -> some View {
        Image(systemName: "plus")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isEnabled ? Color.accentColor : .secondary)
            .frame(width: 26, height: 24)
            .background(Theme.hover, in: Capsule())
            .opacity(isEnabled ? 1 : 0.5)
    }
}

#Preview {
    LogChipsBar()
        .previewEnvironment()
}
