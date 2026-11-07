import SwiftUI
import DevHubDomain
import DevHubUI

struct OperationsTray: View {
    @Environment(OperationLog.self) private var operations
    @Environment(CommandLog.self) private var commandLog

    let origin: OperationOrigin?
    let maxHeight: CGFloat

    var body: some View {
        let cards = OperationsTrayMapper.cards(for: operations.records, entries: commandLog.entries, origin: origin)
        if let expandedID = operations.expandedID, let model = cards.first(where: { $0.id == expandedID }) {
            ViewThatFits(in: .vertical) {
                card(model)
                ScrollView {
                    card(model)
                }
            }
            .frame(maxHeight: maxHeight)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.snappy(duration: 0.2), value: expandedID)
        }
    }

    private func card(_ model: OperationCardModel) -> some View {
        OperationCard(
            model: model,
            onRetry: { operations.retry(model.id) },
            onStop: { operations.stop(model.id) },
            onToggleOutput: { operations.toggleOutput(of: model.id) },
            onDismiss: { operations.toggleExpanded(model.id) }
        )
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Theme.shadow, radius: 8, y: 2)
    }
}

#Preview {
    Color.clear
        .overlay(alignment: .bottom) {
            OperationsTray(origin: nil, maxHeight: 360)
        }
        .previewEnvironment()
}
