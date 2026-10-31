import Foundation

package enum CircleCIStatusMapper {

    package static func status(phase: String?, outcome: String?) -> CheckStatus {
        let outcome = outcome?.trimmingCharacters(in: .whitespaces) ?? ""
        guard outcome.isEmpty || outcome == "unknown" else { return status(outcome) }
        return status(phase ?? "")
    }

    package static func status(_ name: String) -> CheckStatus {
        switch name.lowercased() {
        case "success", "succeeded", "passed": .success
        case "failed", "failing", "error", "errored", "infrastructure_fail", "timedout", "timed_out", "unauthorized": .failed
        case "running", "finishing": .running
        case "on_hold", "needs_approval", "blocked_on_approval", "approval": .manual
        case "canceled", "cancelled", "terminated-unknown": .canceled
        case "not_run", "skipped", "not_running": .skipped
        case "queued", "created", "blocked", "pending", "scheduled", "waiting", "retried": .pending
        case "": .other("unknown")
        default: .other(name.lowercased())
        }
    }
}
