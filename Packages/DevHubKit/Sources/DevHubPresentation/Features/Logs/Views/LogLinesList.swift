import SwiftUI
import DevHubDomain
import DevHubUI

struct LogLinesList: View {
    let rows: [LogLineRowModel]
    let followsTail: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        LogLineRow(model: row)
                            .id(row.id)
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: rows.last?.id) { _, last in
                guard followsTail, let last else { return }
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }
}

#Preview {
    LogLinesList(rows: [.preview], followsTail: true)
        .previewEnvironment()
}
