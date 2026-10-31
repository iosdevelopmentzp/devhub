import SwiftUI
import DevHubDomain
import DevHubUI

struct OperationCard: View {
    @Environment(Toaster.self) private var toaster

    let model: OperationCardModel
    let onRetry: () -> Void
    let onStop: () -> Void
    let onToggleOutput: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if let fraction = model.fraction {
                ProgressView(value: fraction)
                    .controlSize(.small)
            }
            if model.steps.isEmpty == false {
                steps
            }
            if let line = model.liveLine {
                Text(line)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .hintWhenTruncated(line)
            }
            if model.message != nil || model.digest.isEmpty == false {
                failure
            }
            if let output = model.fullOutput {
                fullOutput(output)
            }
            buttons
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(model.tint.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(model.tint.color.opacity(0.25)))
    }

    private var header: some View {
        HStack(spacing: 6) {
            if model.isRunning {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Image(systemName: model.icon)
                    .foregroundStyle(model.tint.color)
            }
            Text(model.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
                .hintWhenTruncated(model.title)
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
            if model.canStop {
                IconButton(systemImage: "stop.fill", help: "Stop", tint: .red, action: onStop)
            }
            if model.canDismiss {
                IconButton(systemImage: "xmark", help: "Hide this result", action: onDismiss)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 3) {
            if model.hiddenStepCount > 0 {
                Text(CountText.count(model.hiddenStepCount, "earlier step", "earlier steps"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            ForEach(model.steps) { step in
                HStack(spacing: 6) {
                    if step.isRunning {
                        ProgressView()
                            .controlSize(.mini)
                            .frame(width: 12)
                    } else {
                        Image(systemName: step.icon)
                            .foregroundStyle(step.tint.color)
                            .frame(width: 12)
                    }
                    Text(step.command)
                        .font(.caption2.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hintWhenTruncated(step.command)
                    Spacer(minLength: 4)
                    if let duration = step.duration {
                        Text(duration)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption2)
            }
        }
    }

    private var failure: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let message = model.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Tint.red.color)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let failedStep = model.failedStep, model.message == nil {
                Text(failedStep)
                    .font(.caption2.monospaced())
                    .foregroundStyle(model.tint.color)
                    .textSelection(.enabled)
            }
            if model.digest.isEmpty == false {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(model.digest.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption2.monospaced())
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }

    private func fullOutput(_ output: String) -> some View {
        ScrollView {
            Text(output)
                .font(.caption2.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
        }
        .frame(maxHeight: 180)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    @ViewBuilder
    private var buttons: some View {
        if model.canRetry || model.errorText != nil || model.hasFullOutput {
            HStack(spacing: 12) {
                if model.canRetry {
                    Button("Retry", action: onRetry)
                        .buttonStyle(LinkButtonStyle(.accent, weight: .medium))
                        .fixedSize()
                }
                if let errorText = model.errorText {
                    Button("Copy Error") {
                        toaster.copy(errorText, label: "the error")
                    }
                    .buttonStyle(LinkButtonStyle(.secondary))
                    .fixedSize()
                }
                if model.hasFullOutput {
                    Button(model.isOutputOpen ? "Hide Output" : "Full Output", action: onToggleOutput)
                        .buttonStyle(LinkButtonStyle(.secondary))
                        .fixedSize()
                }
            }
        }
    }
}

#Preview {
    OperationCard(model: .preview, onRetry: {}, onStop: {}, onToggleOutput: {}, onDismiss: {})
        .padding()
        .frame(width: 520)
        .previewEnvironment()
}
