import SwiftUI
import DevHubDomain
import DevHubUI

struct OperationsStrip: View {
    @Environment(OperationLog.self) private var operations
    @Environment(CommandLog.self) private var commandLog

    let origin: OperationOrigin?

    var body: some View {
        let cards = OperationsTrayMapper.cards(for: operations.records, entries: commandLog.entries, origin: origin)
        let model = OperationStripMapper.model(for: cards, expandedID: operations.expandedID)
        if model.rows.isEmpty == false {
            VStack(spacing: 0) {
                ForEach(model.rows) { row in
                    Divider()
                    OperationStripRow(
                        model: row,
                        onRetry: { operations.retry(row.id) },
                        onStop: { operations.stop(row.id) },
                        onToggle: { operations.toggleExpanded(row.id) },
                        onDismiss: { operations.dismiss(row.id) }
                    )
                    .task(id: row.hidesSoon) {
                        guard row.hidesSoon, (try? await Task.sleep(for: .seconds(4))) != nil else { return }
                        operations.dismiss(row.id)
                    }
                }
                if let moreText = model.moreText {
                    Divider()
                    Text(moreText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .hint("The footer shows every operation of this session. Click the operations there to open the list.")
                }
            }
            .background(Theme.base)
            .animation(.snappy(duration: 0.2), value: model.rows.map(\.id))
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        Color.clear
        OperationsStrip(origin: nil)
    }
    .previewEnvironment()
}
