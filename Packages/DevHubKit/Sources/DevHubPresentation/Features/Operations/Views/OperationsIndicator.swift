import SwiftUI
import DevHubDomain
import DevHubUI

struct OperationsIndicator: View {
    @Environment(OperationLog.self) private var operations

    @State private var isListOpen = false

    var body: some View {
        if let model = OperationsIndicatorMapper.model(for: operations.records) {
            Button {
                isListOpen.toggle()
                operations.markAllSeen()
            } label: {
                HStack(spacing: 5) {
                    if model.isRunning {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: model.icon)
                            .foregroundStyle(model.tint.color)
                    }
                    if let text = model.text {
                        Text(text)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(model.textTint.color)
                    }
                }
                .font(.caption)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hint(model.hint)
            .popover(isPresented: $isListOpen, arrowEdge: .top) {
                OperationsList()
            }
        }
    }
}

#Preview {
    OperationsIndicator()
        .padding()
        .previewEnvironment()
}
