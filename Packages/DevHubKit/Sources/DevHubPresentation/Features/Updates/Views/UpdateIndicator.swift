import SwiftUI
import DevHubDomain
import DevHubUI

struct UpdateIndicator: View {
    @Environment(UpdateStore.self) private var updates

    @State private var isOpen = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if let model = UpdateIndicatorMapper.model(for: updates.state, remoteBranch: updates.installed?.remoteBranch ?? "origin/main", now: context.date) {
                Button {
                    isOpen.toggle()
                } label: {
                    HStack(spacing: 5) {
                        if model.isRunning {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: model.icon)
                                .foregroundStyle(model.tint.color)
                        }
                        Text(model.text)
                            .lineLimit(1)
                            .foregroundStyle(model.isRunning ? Color.secondary : model.tint.color)
                    }
                    .font(.caption)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(model.canOpen == false)
                .hint(model.hint)
                .popover(isPresented: $isOpen, arrowEdge: .top) {
                    UpdatePopover(model: model, log: updates.log) {
                        isOpen = false
                        Task { await updates.update() }
                    }
                }
            }
        }
    }
}

#Preview {
    UpdateIndicator()
        .padding()
        .previewEnvironment()
}
