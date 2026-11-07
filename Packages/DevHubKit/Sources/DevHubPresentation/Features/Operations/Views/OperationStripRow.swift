import SwiftUI
import DevHubDomain
import DevHubUI

struct OperationStripRow: View {
    let model: OperationStripModel
    let onRetry: () -> Void
    let onStop: () -> Void
    let onToggle: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if model.isRunning {
                ProgressView()
                    .controlSize(.mini)
                    .frame(width: 12)
            } else {
                Image(systemName: model.icon)
                    .foregroundStyle(model.tint.color)
                    .frame(width: 12)
            }
            Text(model.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
                .layoutPriority(1)
                .hintWhenTruncated(model.title)
            if let summary = model.summary {
                Text(summary)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .hintWhenTruncated(summary)
            }
            Spacer(minLength: 4)
            if model.isRunning {
                if let detail = model.detail {
                    Text(detail)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Text(model.startedAt, style: .timer)
                    .monospacedDigit()
            } else if let detail = model.detail {
                Text(detail)
            }
            if model.canRetry {
                Button("Retry", action: onRetry)
                    .buttonStyle(LinkButtonStyle(.accent, weight: .medium))
                    .fixedSize()
            }
            if model.canStop {
                IconButton(systemImage: "stop.fill", help: "Stop", tint: .red, action: onStop)
            }
            if model.canExpand {
                IconButton(systemImage: model.isExpanded ? "chevron.down" : "chevron.up", help: model.expandHint, action: onToggle)
            }
            if model.canDismiss {
                IconButton(systemImage: "xmark", help: "Hide this result", action: onDismiss)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(model.tint.color.opacity(0.08))
        .overlay(alignment: .bottomLeading) {
            if let fraction = model.fraction {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(model.tint.color.opacity(0.7))
                        .frame(width: geometry.size.width * fraction, height: 2)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard model.canExpand else { return }
            onToggle()
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        OperationStripRow(model: .preview, onRetry: {}, onStop: {}, onToggle: {}, onDismiss: {})
        OperationStripRow(
            model: OperationStripModel(id: UUID(), title: "Regenerate Project", icon: "circle.dotted", tint: .blue, isRunning: true, startedAt: Date(), detail: "Step 2 of 3", summary: "./scripts/regenerate.sh", fraction: 0.6, canRetry: false, canStop: true, canDismiss: false, canExpand: true, isExpanded: true, expandHint: "Hide the card of this operation", hidesSoon: false),
            onRetry: {},
            onStop: {},
            onToggle: {},
            onDismiss: {}
        )
    }
    .frame(width: 640)
    .previewEnvironment()
}
