import Foundation

package enum CIAutoRerunPolicy {
    package static let attemptChoices = [3, 5, 10, 20]
    package static let defaultMaxAttempts = 10
    package static let newWorkflowGrace: TimeInterval = 600

    package enum Decision: Hashable, Sendable {
        case handled
        case wait
        case rerun
        case succeeded
        case cancelled
        case exhausted
    }

    package enum Outcome: Hashable, Sendable {
        case wait
        case rerun
        case succeeded
        case cancelled
        case exhausted
    }

    package static func decision(for workflow: CIWorkflow, plan: CIAutoRerunPlan, now: Date) -> Decision {
        if plan.handledWorkflowIDs.contains(workflow.id) {
            guard let lastRerunAt = plan.lastRerunAt, now.timeIntervalSince(lastRerunAt) < newWorkflowGrace else { return .handled }
            return .wait
        }
        switch workflow.status {
        case .success, .skipped: return .succeeded
        case .failed: return plan.attempts < plan.maxAttempts ? .rerun : .exhausted
        case .canceled: return .cancelled
        default: return .wait
        }
    }

    package static func outcome(of decisions: [Decision]) -> Outcome {
        if decisions.contains(.exhausted) { return .exhausted }
        if decisions.contains(.cancelled) { return .cancelled }
        if decisions.contains(.rerun) { return .rerun }
        let open = decisions.filter { $0 != .handled }
        guard open.isEmpty == false, open.allSatisfy({ $0 == .succeeded }) else { return .wait }
        return .succeeded
    }
}
