import SwiftUI
import DevHubDomain
import DevHubUI

struct DiskCleanupSection: View {
    @Environment(DiskCleanupStore.self) private var store

    @State private var confirmingID: DiskCleanupItem.ID?
    @State private var expandedGroups: Set<DiskCleanupKind> = []

    var body: some View {
        let model = DiskCleanupMapper.model(items: store.items, sizes: store.sizes, measuringIDs: store.measuringIDs, busyIDs: store.busyIDs)
        Section {
            VStack(alignment: .leading, spacing: 0) {
                if let failure = store.failure {
                    Text(failure)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        .padding(.vertical, 6)
                } else if model.isEmpty {
                    Text(store.hasScanned ? "Nothing to clean." : "Reading the folders…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                }
                ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Divider()
                    }
                    rowView(row)
                }
                ForEach(model.groups) { group in
                    if model.rows.isEmpty == false || group.id != model.groups.first?.id {
                        Divider()
                    }
                    groupHeader(group)
                    if expandedGroups.contains(group.id) {
                        ForEach(group.rows) { row in
                            Divider()
                                .padding(.leading, 30)
                            rowView(row)
                                .padding(.leading, 30)
                        }
                    }
                }
            }
            .animation(.snappy(duration: 0.18), value: confirmingID)
            .animation(.snappy(duration: 0.18), value: expandedGroups)
        } header: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Disk")
                    if let total = model.totalText {
                        Text(total)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if store.isScanning {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Button("Scan Again") {
                        Task { await store.scan() }
                    }
                    .controlSize(.small)
                    .disabled(store.isScanning)
                }
            }
        } footer: {
            Text("Xcode, simulator and package manager folders that every Mac has. DevHub reads the sizes with du and the simulators with simctl. Deleted files do not go to the Trash.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task {
            await store.scanIfNeeded()
        }
    }

    private func groupHeader(_ group: DiskCleanupGroupModel) -> some View {
        let isExpanded = expandedGroups.contains(group.id)
        return Button {
            if isExpanded {
                expandedGroups.remove(group.id)
            } else {
                expandedGroups.insert(group.id)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 10)
                Image(systemName: group.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text(group.title)
                    .font(.callout.weight(.medium))
                Spacer(minLength: 8)
                Text(group.summary)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .hint(isExpanded ? "Hide the lines" : "Show one line each")
    }

    private func rowView(_ row: DiskCleanupRowModel) -> some View {
        DiskCleanupRow(
            model: row,
            isConfirming: confirmingID == row.id,
            onRequestDelete: { confirmingID = row.id },
            onCancel: { confirmingID = nil },
            onConfirm: {
                confirmingID = nil
                store.clean(row.id)
            }
        )
    }
}

#Preview {
    Form {
        DiskCleanupSection()
    }
    .formStyle(.grouped)
    .previewEnvironment()
}
