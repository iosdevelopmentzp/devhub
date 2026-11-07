import SwiftUI
import DevHubDomain
import DevHubUI

struct CustomTabHistorySection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigActionsStore.self) private var store

    let tabID: String

    var body: some View {
        let records = store.copyHistory(in: tabID).filter { session.matchesSearch($0.text, $0.title) }
        if records.isEmpty == false {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader("Recent") {
                    Button("Clear") {
                        store.clearCopyHistory(in: tabID)
                    }
                    .buttonStyle(LinkButtonStyle(.secondary))
                }
                PanelCard {
                    VStack(spacing: 0) {
                        ForEach(records) { record in
                            CopyHistoryRow(
                                model: CopyHistoryRowMapper.model(for: record),
                                onResend: { store.resend(record) },
                                onRemove: { store.removeCopy(id: record.id) }
                            )
                            if record.id != records.last?.id {
                                Divider()
                                    .padding(.leading, 14)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CustomTabHistorySection(tabID: "chat")
        .padding()
        .previewEnvironment()
}
