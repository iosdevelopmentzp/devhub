import SwiftUI
import DevHubDomain
import DevHubUI

struct OperationsList: View {
    @Environment(OperationLog.self) private var operations
    @Environment(CommandLog.self) private var commandLog

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Operations")
                    .font(.callout.weight(.semibold))
                Spacer()
                Button("Clear Finished") {
                    operations.clearFinished()
                }
                .buttonStyle(LinkButtonStyle(.secondary))
                .disabled(operations.records.allSatisfy(\.isRunning))
                .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            Divider()
            if operations.records.isEmpty {
                Text("Git actions, scripts and other commands show here with their steps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(operations.newestFirst) { record in
                            OperationCard(
                                model: OperationCardMapper.model(for: record, entries: commandLog.entries),
                                onRetry: { operations.retry(record.id) },
                                onStop: { operations.stop(record.id) },
                                onToggleOutput: { operations.toggleOutput(of: record.id) },
                                onDismiss: { operations.remove(record.id) }
                            )
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 460)
            }
        }
        .frame(width: 460)
        .background(Theme.surface)
    }
}

#Preview {
    OperationsList()
        .previewEnvironment()
}
