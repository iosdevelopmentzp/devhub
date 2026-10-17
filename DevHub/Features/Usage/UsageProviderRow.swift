import SwiftUI

struct UsageProviderRow: View {
    @Environment(UsageStore.self) private var store

    let id: UsageProviderID

    private var entry: UsageEntry { store.entry(id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text(id.title)
                    .font(.caption.weight(.semibold))
                    .frame(width: 50, alignment: .leading)
                content
                Spacer(minLength: 0)
                if entry.isLoading {
                    ProgressView().controlSize(.mini)
                }
                Image(systemName: store.isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture { store.isExpanded.toggle() }
            if store.isExpanded {
                UsageDetails(id: id, entry: entry) { Task { await store.refresh(id) } }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var content: some View {
        if let error = entry.error {
            Text(error)
                .font(.caption)
                .foregroundStyle(Tint.red.color)
                .lineLimit(1)
                .hintWhenTruncated(error)
            Button("Retry") { Task { await store.refresh(id) } }
                .controlSize(.small)
                .fixedSize()
        } else if let usage = entry.usage {
            if usage.meters.isEmpty {
                Text(usage.note ?? usage.plan ?? "No limit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(usage.meters.prefix(2)) { meter in
                UsageMeterBar(meter: meter)
            }
            if let reset = usage.meters.first(where: { $0.id == "premium" })?.resetsAt {
                Text("resets \(reset.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
    }
}

#Preview {
    UsageProviderRow(id: .claude)
        .previewEnvironment()
}
