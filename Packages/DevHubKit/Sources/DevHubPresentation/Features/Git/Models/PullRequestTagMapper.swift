import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestTagMapper {

    static func conflictsTag(targetBranch: String, words: CodeHostWords) -> TagModel {
        TagModel(
            "conflicts",
            tint: .red,
            systemImage: "exclamationmark.triangle.fill",
            hint: "\(words.hostTitle) cannot merge it: \(words.catchUp(target: targetBranch)) and solve the conflicts"
        )
    }

    static func detailTag(_ detail: MergeDetail, words: CodeHostWords) -> TagModel? {
        guard let text = detailText(detail, words: words) else { return nil }
        return TagModel(text.title, tint: text.tint, hint: "\(words.hostTitle) merge status: \(detail.name)")
    }

    static func pipelineTag(_ pipeline: PipelineInfo, subject: String, words: CodeHostWords) -> TagModel {
        TagModel(
            "\(words.checks) \(words.status(pipeline.status))",
            tint: pipelineTint(pipeline.status),
            systemImage: pipelineIcon(pipeline.status),
            hint: "\(subject)\(pipeline.updatedAt.map { ", \($0.relativeDescription)" } ?? ""). Click to open it."
        )
    }

    static func compactPipelineTag(_ pipeline: PipelineInfo, words: CodeHostWords) -> TagModel {
        switch pipeline.status {
        case .success:
            return .icon(
                pipelineIcon(.success),
                tint: .green,
                hint: "\(words.checks("passed", "passed"))\((pipeline.finishedAt ?? pipeline.updatedAt).map { " \($0.relativeDescription)" } ?? ""). Click to open it."
            )
        case .running:
            return TagModel("running", tint: .blue, systemImage: pipelineIcon(.running), hint: "\(words.checks("is running", "are running")). Click to open it.")
        case .pending, .created, .waitingForResource, .preparing, .scheduled:
            return TagModel("pending", tint: .orange, systemImage: pipelineIcon(.pending), hint: "\(words.checks("waits", "wait")) to start (\(pipeline.status.name)). Click to open it.")
        case .failed:
            return TagModel("\(words.checks) failed", tint: .red, systemImage: pipelineIcon(.failed), hint: "\(failedJobsText(pipeline.failedJobCount, words: words)). Click to open it.")
        default:
            return TagModel("\(words.checks) \(words.status(pipeline.status))", tint: pipelineTint(pipeline.status), systemImage: pipelineIcon(pipeline.status), hint: "\(words.checksTitle) of the last commit. Click to open it.")
        }
    }

    static func approvalTag(approvedBy: [String], username: String?) -> TagModel? {
        guard approvedBy.isEmpty == false else { return nil }
        let names = approvedBy.map { $0 == username ? "you" : $0 }
        return TagModel(
            approvedBy.contains { $0 == username } ? "you approved" : "approved by \(approverText(approvedBy))",
            tint: .green,
            systemImage: "checkmark.seal.fill",
            hint: "Approved by \(names.joined(separator: ", "))"
        )
    }

    static func openThreadsTag(open: Int, total: Int, comments: Int) -> TagModel? {
        guard open > 0 else { return nil }
        return TagModel(
            CountText.count(open, "open thread"),
            tint: .orange,
            systemImage: "bubble.left.and.bubble.right",
            hint: "\(total - open) of \(CountText.count(total, "thread")) resolved, \(CountText.count(comments, "comment")) in all"
        )
    }

    static func behindTag(targetBranch: String, words: CodeHostWords) -> TagModel {
        TagModel(
            "behind \(targetBranch)",
            tint: .orange,
            systemImage: "arrow.down",
            hint: "The source branch is behind \(targetBranch). \(words.updateWord.capitalized) brings it up to date"
        )
    }

    private static func approverText(_ names: [String]) -> String {
        guard names.count > 2 else { return names.joined(separator: ", ") }
        return "\(names[0]) +\(names.count - 1)"
    }

    private static func failedJobsText(_ count: Int?, words: CodeHostWords) -> String {
        guard let count, count > 0 else { return words.checks("failed", "failed") }
        return "\(CountText.count(count, words.job)) failed"
    }

    private static func pipelineTint(_ status: PipelineStatus) -> Tint {
        switch status {
        case .success: .green
        case .failed: .red
        case .running: .blue
        case .pending, .created, .waitingForResource, .preparing, .scheduled: .orange
        default: .secondary
        }
    }

    private static func pipelineIcon(_ status: PipelineStatus) -> String {
        switch status {
        case .success: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        case .running: "play.circle.fill"
        case .canceled, .skipped: "slash.circle"
        default: "clock"
        }
    }

    private static func detailText(_ detail: MergeDetail, words: CodeHostWords) -> (title: String, tint: Tint)? {
        switch detail {
        case .mergeable: ("ready to merge", .green)
        case .notApproved: ("needs approval", .orange)
        case .ciMustPass, .ciStillRunning: ("waiting for \(words.kind == .gitlab ? "CI" : "checks")", .blue)
        case .discussionsNotResolved: ("open threads", .orange)
        case .needRebase: ("needs \(words.updateWord)", .orange)
        case .draftStatus, .other("unchecked"), .other("checking"): nil
        case .other(let name): (name.replacingOccurrences(of: "_", with: " "), .secondary)
        }
    }
}
