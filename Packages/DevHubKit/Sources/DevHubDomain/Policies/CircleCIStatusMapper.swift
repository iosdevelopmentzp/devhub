import Foundation

package enum CircleCIStatusMapper {

    package static func status(phase: String?, outcome: String?) -> CheckStatus {
        status(phase: phase, outcome: outcome, currentOutcome: nil)
    }

    package static func status(phase: String?, outcome: String?, currentOutcome: String?) -> CheckStatus {
        let phase = clean(phase)
        let outcome = clean(outcome)
        let current = clean(currentOutcome)
        switch phase {
        case "created", "queued":
            return .pending
        case "started":
            return .running
        case "ended":
            return status(outcome.isEmpty ? current : outcome)
        default:
            guard outcome.isEmpty else { return status(outcome) }
            return status(phase)
        }
    }

    package static func jobStatus(phase: String?, outcome: String?, currentOutcome: String?, isApproval: Bool) -> CheckStatus {
        guard isApproval, clean(phase) == "started" else { return status(phase: phase, outcome: outcome, currentOutcome: currentOutcome) }
        return .manual
    }

    package static func status(_ name: String) -> CheckStatus {
        switch name.lowercased() {
        case "success", "succeeded", "passed": .success
        case "failed", "failing", "error", "errored", "infrastructure_fail", "timedout", "timed_out", "unauthorized": .failed
        case "running", "finishing", "started": .running
        case "on_hold", "needs_approval", "blocked_on_approval", "approval": .manual
        case "canceled", "cancelled", "canceling", "terminated-unknown": .canceled
        case "not_run", "skipped", "not_running": .skipped
        case "queued", "created", "blocked", "pending", "scheduled", "waiting", "retried": .pending
        case "": .other("unknown")
        default: .other(name.lowercased())
        }
    }

    private static func clean(_ value: String?) -> String {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        return trimmed == "unknown" ? "" : trimmed
    }
}
