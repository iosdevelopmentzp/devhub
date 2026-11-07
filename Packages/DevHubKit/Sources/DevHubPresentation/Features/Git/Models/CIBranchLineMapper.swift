import Foundation
import DevHubDomain
import DevHubUI

enum CIBranchLineMapper {

    static func model(
        run: CIRun?,
        workflows: [CIWorkflow],
        error: String?,
        isLoading: Bool,
        loadedBranch: String?,
        branch: String?,
        busy: Set<String>,
        slug: String?,
        base: URL?,
        words: CodeHostWords
    ) -> CIBranchLineModel {
        CIBranchLineModel(
            content: content(run: run, workflows: workflows, error: error, loadedBranch: loadedBranch, branch: branch, busy: busy, words: words),
            isLoading: isLoading,
            openURL: branch.flatMap { CIJobLink.pipelinesURL(base: base, slug: slug, branch: $0) },
            iconHint: "CircleCI runs of this branch, read with circleci (run list, workflow list)"
        )
    }

    private static func content(run: CIRun?, workflows: [CIWorkflow], error: String?, loadedBranch: String?, branch: String?, busy: Set<String>, words: CodeHostWords) -> CIBranchLineModel.Content {
        if let error {
            return .failure(error)
        }
        guard let branch, loadedBranch == branch else { return .checking }
        guard let run else { return .noRun("No CircleCI run for this branch") }
        return .run(
            CIBranchLineModel.Run(
                subject: run.subject,
                ageText: run.createdAt?.relativeDescription,
                workflows: workflows.map { workflow(for: $0, run: run, busy: busy.contains($0.id), words: words) }
            )
        )
    }

    private static func workflow(for workflow: CIWorkflow, run: CIRun, busy: Bool, words: CodeHostWords) -> CIBranchLineModel.Workflow {
        let name = workflow.name.isEmpty ? "workflow" : workflow.name
        let status = PipelineJobRowMapper.ciStatusText(workflow.status, words: words)
        return CIBranchLineModel.Workflow(
            id: workflow.id,
            name: name,
            tag: TagModel(
                "\(name) \(status)",
                tint: PullRequestTagMapper.pipelineTint(workflow.status),
                systemImage: workflow.status == .manual ? "hand.raised" : PullRequestTagMapper.pipelineIcon(workflow.status),
                hint: "CircleCI workflow \(name) \(status)\(run.createdAt.map { ", started \($0.relativeDescription)" } ?? "")\(run.subject.map { ". \($0)" } ?? "")"
            ),
            isBusy: busy,
            canRerun: workflow.status == .failed || workflow.status == .canceled,
            canCancel: PipelineStatePolicy.isActive(workflow.status) || workflow.status == .manual,
            rerunHint: "Run the failed jobs of \(name) again (circleci workflow rerun --from-failed)",
            cancelHint: "Cancel \(name) (circleci workflow cancel)"
        )
    }
}
