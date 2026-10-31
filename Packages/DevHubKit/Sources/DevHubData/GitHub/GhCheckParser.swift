import Foundation
import DevHubDomain

enum GhCheckParser {
    struct CommitNode: Decodable {
        let commit: Commit
    }

    struct Commit: Decodable {
        let statusCheckRollup: Rollup?
    }

    struct Rollup: Decodable {
        struct Contexts: Decodable {
            let nodes: [Context]
        }

        let state: String
        let contexts: Contexts
    }

    struct Context: Decodable {
        struct Suite: Decodable {
            struct Run: Decodable {
                struct Workflow: Decodable {
                    let name: String?
                }

                let databaseId: Int?
                let workflow: Workflow?
            }

            let workflowRun: Run?
        }

        let databaseId: Int?
        let name: String?
        let title: String?
        let conclusion: String?
        let status: String?
        let detailsUrl: String?
        let startedAt: Date?
        let completedAt: Date?
        let checkSuite: Suite?
        let context: String?
        let state: String?
        let targetUrl: String?

        var displayName: String {
            name ?? context ?? ""
        }

        var url: String? {
            detailsUrl ?? targetUrl
        }

        var runID: Int? {
            checkSuite?.workflowRun?.databaseId
        }

        var workflowName: String? {
            checkSuite?.workflowRun?.workflow?.name
        }

        var duration: Int? {
            guard let startedAt, let completedAt, completedAt >= startedAt else { return nil }
            return Int(completedAt.timeIntervalSince(startedAt))
        }

        var failureMessage: String? {
            guard isFailed, let title, title.isEmpty == false, title != displayName else { return nil }
            return title
        }

        var isFailed: Bool {
            if let conclusion { return GhCheckParser.failedConclusions.contains(conclusion) }
            return state == "FAILURE" || state == "ERROR"
        }

        var isRunning: Bool {
            status == "IN_PROGRESS"
        }
    }

    static let failedConclusions: Set<String> = ["FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE"]

    static func pipeline(_ rollup: Rollup, fallbackURL: String?) -> PipelineInfo {
        let checks = rollup.contexts.nodes
        let failed = checks.filter(\.isFailed)
        let finished = checks.compactMap(\.completedAt)
        let isFinished = checks.isEmpty == false && finished.count == checks.filter { $0.name != nil }.count
        return PipelineInfo(
            status: status(rollup.state, checks: checks),
            webURL: (failed.first?.url ?? fallbackURL).flatMap(URL.init(string:)),
            updatedAt: finished.max(),
            id: failed.first?.runID ?? checks.lazy.compactMap(\.runID).first,
            duration: duration(rollup),
            finishedAt: isFinished ? finished.max() : nil,
            failedJobCount: failed.count
        )
    }

    static func failedJobs(_ rollup: Rollup) -> [PipelineJob] {
        rollup.contexts.nodes
            .filter(\.isFailed)
            .map { PipelineJob(name: $0.displayName, stage: nil, webURL: $0.url.flatMap(URL.init(string:))) }
    }

    static func jobs(_ rollup: Rollup) -> [PipelineJob] {
        rollup.contexts.nodes
            .filter { $0.displayName.isEmpty == false }
            .map { context in
                PipelineJob(
                    name: context.displayName,
                    stage: context.workflowName,
                    webURL: context.url.flatMap(URL.init(string:)),
                    id: context.runID == nil ? nil : context.databaseId.map(String.init),
                    status: jobStatus(context),
                    duration: context.duration,
                    failureMessage: context.failureMessage,
                    ciWorkflowID: CIWorkflowLink.parse(context.url)?.workflowID
                )
            }
    }

    static func jobStatus(_ context: Context) -> CheckStatus {
        if context.isFailed { return .failed }
        if let conclusion = context.conclusion {
            switch conclusion {
            case "SUCCESS", "NEUTRAL": return .success
            case "SKIPPED": return .skipped
            default: return .other(conclusion.lowercased())
            }
        }
        switch context.status ?? context.state {
        case "IN_PROGRESS": return .running
        case "QUEUED", "PENDING", "EXPECTED", "WAITING", "REQUESTED": return .pending
        case "SUCCESS": return .success
        default: return .other((context.status ?? context.state ?? "").lowercased())
        }
    }

    static func duration(_ rollup: Rollup) -> Int? {
        let checks = rollup.contexts.nodes
        guard let start = checks.compactMap(\.startedAt).min(), let end = checks.compactMap(\.completedAt).max(), end >= start else { return nil }
        return Int(end.timeIntervalSince(start))
    }

    private static func status(_ state: String, checks: [Context]) -> CheckStatus {
        switch state {
        case "SUCCESS": .success
        case "FAILURE", "ERROR": .failed
        case "PENDING", "EXPECTED": checks.contains(where: \.isRunning) ? .running : .pending
        default: .other(state.lowercased())
        }
    }
}
