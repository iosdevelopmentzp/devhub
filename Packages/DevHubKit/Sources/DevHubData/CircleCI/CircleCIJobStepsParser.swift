import Foundation
import DevHubDomain

enum CircleCIJobStepsParser {
    private struct Job: Decodable {
        let executions: [Execution]?
    }

    private struct Execution: Decodable {
        let index: Int?
        let steps: [Step]?
    }

    private struct Step: Decodable {
        let num: Int?
        let name: String?
        let phase: String?
        let outcome: String?
        let status: String?
        let exitCode: Int?
        let startedAt: String?
        let stoppedAt: String?
    }

    static func steps(from data: Data) throws -> [CIJobStep] {
        let job = try CircleCIJSON.decode(Job.self, from: data)
        let execution = (job.executions ?? []).max { ($0.index ?? 0) < ($1.index ?? 0) }
        return (execution?.steps ?? []).enumerated().map { offset, step in
            CIJobStep(
                index: step.num ?? offset,
                name: step.name ?? "Step \(step.num ?? offset)",
                status: CircleCIStatusMapper.status(phase: step.phase ?? step.status, outcome: step.outcome, currentOutcome: nil),
                duration: duration(from: step.startedAt, to: step.stoppedAt),
                exitCode: step.exitCode
            )
        }
    }

    private static func duration(from start: String?, to end: String?) -> TimeInterval? {
        guard let start = start.flatMap(ISO8601.date(from:)), let end = end.flatMap(ISO8601.date(from:)) else { return nil }
        return max(0, end.timeIntervalSince(start))
    }
}
