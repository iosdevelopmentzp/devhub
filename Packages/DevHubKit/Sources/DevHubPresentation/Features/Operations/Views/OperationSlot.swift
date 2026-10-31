import SwiftUI
import DevHubDomain
import DevHubUI

struct OperationSlot: View {
    @Environment(OperationLog.self) private var operations
    @Environment(CommandLog.self) private var commandLog

    let origin: OperationOrigin

    var body: some View {
        if let record = operations.latest(at: origin) {
            let model = OperationCardMapper.model(for: record, entries: commandLog.entries)
            OperationCard(
                model: model,
                onRetry: { operations.retry(record.id) },
                onStop: { operations.stop(record.id) },
                onToggleOutput: { operations.toggleOutput(of: record.id) },
                onDismiss: { operations.dismiss(record.id) }
            )
            .task(id: model.hidesSoon) {
                guard model.hidesSoon, (try? await Task.sleep(for: .seconds(4))) != nil else { return }
                operations.dismiss(record.id)
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    OperationSlot(origin: .git)
        .padding()
        .previewEnvironment()
}
