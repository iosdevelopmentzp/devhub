import SwiftUI
import DevHubDomain
import DevHubUI

struct NetworkRequestList: View {
    let rows: [NetworkRequestRowModel]
    let detail: NetworkRequestDetailModel?
    let onToggle: (NetworkRequest.ID) -> Void
    let onMockThis: ((NetworkRequest.ID) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(rows) { row in
                    NetworkRequestRow(model: row) {
                        onToggle(row.id)
                    }
                    if row.isSelected, let detail {
                        NetworkRequestDetail(model: detail, onMockThis: onMockThis.map { action in { action(row.id) } })
                    }
                    if row.id != rows.last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NetworkRequestList(rows: [.preview], detail: .preview, onToggle: { _ in }, onMockThis: { _ in })
        .previewEnvironment()
}
