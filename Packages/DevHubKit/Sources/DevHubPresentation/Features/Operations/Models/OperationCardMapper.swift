import Foundation
import DevHubDomain
import DevHubUI

enum OperationCardMapper {
    static let stepLimit = 6

    static func model(for record: OperationRecord, entries: [CommandLog.Entry]) -> OperationCardModel {
        let steps = entries.filter { $0.operationID == record.id && ($0.kind != .read || $0.isFailure) }
        let failedStep = steps.last(where: \.isFailure)
        let shownSteps = steps.suffix(stepLimit)
        let outputStep = failedStep ?? steps.last
        let message = record.failureMessage
        let digest = failedStep.map { FailureDigestPolicy.digest($0.lines) } ?? []
        let newDigest = digest.filter { line in message?.contains(line) != true }
        let look = look(for: record, hasFailedStep: failedStep != nil)
        return OperationCardModel(
            id: record.id,
            title: look.title,
            icon: look.icon,
            tint: look.tint,
            isRunning: record.isRunning,
            startedAt: record.startedAt,
            detail: detail(for: record),
            fraction: record.isRunning ? record.fraction.map { min(max($0, 0), 1) } : nil,
            steps: shownSteps.map(step),
            hiddenStepCount: steps.count - shownSteps.count,
            liveLine: record.isRunning ? liveLine(of: steps.last(where: \.isRunning)) : nil,
            message: message,
            failedStep: failedStep.map(failedStepText),
            digest: newDigest,
            fullOutput: record.isOutputOpen ? outputStep?.output : nil,
            hasFullOutput: record.isRunning == false && outputStep?.lines.isEmpty == false,
            isOutputOpen: record.isOutputOpen,
            canRetry: record.canRetry && record.isRunning == false && (message != nil || failedStep != nil),
            canStop: record.canStop && record.isRunning,
            canDismiss: record.isRunning == false,
            hidesSoon: record.status == .succeeded && failedStep == nil,
            errorText: errorText(look.title, message: message, failedStep: failedStep, digest: digest)
        )
    }

    private static func look(for record: OperationRecord, hasFailedStep: Bool) -> (title: String, icon: String, tint: Tint) {
        switch record.status {
        case .running:
            (record.title, "circle.dotted", .blue)
        case .succeeded where hasFailedStep:
            ("\(record.title) · a step failed", "exclamationmark.triangle.fill", .orange)
        case .succeeded:
            (record.title, "checkmark.circle.fill", .green)
        case .failed:
            ("\(record.title) failed", "xmark.octagon.fill", .red)
        case .cancelled:
            ("\(record.title) stopped", "stop.circle", .secondary)
        }
    }

    private static func detail(for record: OperationRecord) -> String? {
        guard let finishedAt = record.finishedAt else { return record.progressText }
        return DurationFormat.text(finishedAt.timeIntervalSince(record.startedAt))
    }

    private static func step(_ entry: CommandLog.Entry) -> OperationCardModel.Step {
        let look: (icon: String, tint: Tint) = entry.isRunning
            ? ("circle.dotted", .blue)
            : entry.isFailure ? ("xmark.circle.fill", .red) : ("checkmark.circle.fill", .green)
        return OperationCardModel.Step(
            id: entry.id,
            command: entry.command,
            icon: look.icon,
            tint: look.tint,
            isRunning: entry.isRunning,
            duration: entry.finishedAt.map { DurationFormat.text($0.timeIntervalSince(entry.startedAt)) }
        )
    }

    private static func liveLine(of entry: CommandLog.Entry?) -> String? {
        entry?.lines.reversed().lazy.map(FailureDigestPolicy.clean).first { $0.isEmpty == false }
    }

    private static func failedStepText(_ entry: CommandLog.Entry) -> String {
        if let code = entry.exitCode {
            return "\(entry.command) · exit \(code)"
        }
        guard let error = entry.error else { return entry.command }
        return "\(entry.command) · \(error)"
    }

    private static func errorText(_ title: String, message: String?, failedStep: CommandLog.Entry?, digest: [String]) -> String? {
        guard message != nil || failedStep != nil else { return nil }
        let command = failedStep.map { ["$ " + failedStepText($0)] } ?? []
        return ([title] + [message].compactMap { $0 } + command + digest).joined(separator: "\n")
    }
}
