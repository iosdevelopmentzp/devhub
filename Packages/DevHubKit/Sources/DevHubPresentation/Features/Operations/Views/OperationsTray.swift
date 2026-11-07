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
        if cards.isEmpty == false {
            ViewThatFits(in: .vertical) {
                stack(cards)
                ScrollView {
                    stack(cards)
                }
            }
            .frame(maxHeight: maxHeight)
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            .animation(.snappy(duration: 0.2), value: cards.map(\.id))
        }
    }

    private func stack(_ cards: [OperationCardModel]) -> some View {
        VStack(spacing: 8) {
            ForEach(cards) { model in
                OperationCard(
                    model: model,
                    onRetry: { operations.retry(model.id) },
                    onStop: { operations.stop(model.id) },
                    onToggleOutput: { operations.toggleOutput(of: model.id) },
                    onDismiss: { operations.dismiss(model.id) }
                )
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: Theme.shadow, radius: 8, y: 2)
                .task(id: model.hidesSoon) {
                    guard model.hidesSoon, (try? await Task.sleep(for: .seconds(4))) != nil else { return }
                    operations.dismiss(model.id)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    Color.clear
        .overlay(alignment: .bottom) {
            OperationsTray(origin: nil, maxHeight: 360)
        }
        .previewEnvironment()
}
