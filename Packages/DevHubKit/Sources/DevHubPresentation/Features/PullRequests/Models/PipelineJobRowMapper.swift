import Foundation
import DevHubDomain
import DevHubUI

enum PipelineJobRowMapper {
    private enum Unit: Equatable {
        case stage(String)
        case workflow(String)
    }

    private static let unfinishedStatuses: [CheckStatus] = [.running, .pending, .created, .preparing, .waitingForResource, .scheduled]
    static let circleCILogHint = "Show the log: the failed steps first, then the others"

    static func groups(for jobs: [PipelineJob], review: PullRequestReviewState, words: CodeHostWords, now: Date) -> [PipelineJobGroupModel] {
        var order: [Unit] = []
        var members: [String: [(offset: Int, job: PipelineJob)]] = [:]
        var links: [String: CIWorkflowLink.Link] = [:]
        for (offset, job) in jobs.enumerated() {
            if let workflowID = job.ciWorkflowID, review.ciWorkflows[workflowID] != nil {
                if order.contains(.workflow(workflowID)) == false {
                    order.append(.workflow(workflowID))
                }
                if links[workflowID] == nil, let link = CIWorkflowLink.parse(job.webURL?.absoluteString) {
                    links[workflowID] = link
                }
                continue
            }
            let key = job.stage ?? ""
            if members[key] == nil {
                order.append(.stage(key))
            }
            members[key, default: []].append((offset, job))
        }
        let showsTitles = order.contains { $0 != .stage("") }
        var groups: [PipelineJobGroupModel] = []
        for unit in order {
            switch unit {
            case .workflow(let workflowID):
                guard let workflow = review.ciWorkflows[workflowID] else { continue }
                groups.append(group(for: workflow, link: links[workflowID], review: review, words: words, now: now))
            case .stage(let key):
                let group = members[key] ?? []
                let rows = group
                    .sorted { (rank($0.job.status), $0.offset) < (rank($1.job.status), $1.offset) }
                    .map { model(for: $0.job, index: $0.offset, review: review, words: words) }
                let status = groupStatus(group.map(\.job))
                groups.append(
                    PipelineJobGroupModel(
                        id: key.isEmpty ? "-" : key,
                        title: showsTitles ? (key.isEmpty ? "other" : key) : nil,
                        icon: PullRequestTagMapper.pipelineIcon(status),
                        tint: PullRequestTagMapper.pipelineTint(status),
                        statusText: counts(for: group.map(\.job)) ?? words.status(status),
                        jobs: rows
                    )
                )
            }
        }
        return groups
    }

    static func title(for jobs: [PipelineJob], words: CodeHostWords) -> String {
        (["\(words.checksTitle) \(jobs.count)"] + [counts(for: jobs)].compactMap { $0 }).joined(separator: " · ")
    }

    static func model(for job: PipelineJob, index: Int, review: PullRequestReviewState, words: CodeHostWords) -> PipelineJobRowModel {
        let key = job.id ?? "\(index):\(job.name)"
        let isFinished = unfinishedStatuses.contains(job.status) == false
        let failedButAllowed = job.status == .failed && job.allowsFailure
        let isDetailsOpen = review.openJobDetails.contains(key)
        return PipelineJobRowModel(
            id: key,
            jobID: job.id,
            title: job.name,
            icon: PullRequestTagMapper.pipelineIcon(job.status),
            tint: failedButAllowed ? .orange : PullRequestTagMapper.pipelineTint(job.status),
            statusText: words.status(job.status),
            durationText: job.duration.map { DurationFormat.text(TimeInterval($0)) },
            allowedToFailText: job.allowsFailure ? "allowed to fail" : nil,
            failureText: job.failureMessage,
            url: job.webURL,
            canShowLog: job.id != nil && isFinished && job.status != .skipped,
            isLogOpen: job.id.map(review.openJobLogs.contains) ?? false,
            log: job.id.flatMap { review.jobLogs[$0] },
            canRetry: job.id != nil && [.failed, .canceled].contains(job.status),
            retryHint: "Run this \(words.job) again",
            isBusy: job.id.map(review.busyJobs.contains) ?? false,
            noteText: ciNote(for: job, review: review),
            detailsTitle: job.failureMessage == nil ? nil : "reason",
            detailsHint: isDetailsOpen ? "Hide the failure message" : "Show why this \(words.job) failed",
            isDetailsOpen: isDetailsOpen
        )
    }

    static func group(for workflow: CIWorkflow, link: CIWorkflowLink.Link?, review: PullRequestReviewState, words: CodeHostWords, now: Date) -> PipelineJobGroupModel {
        let rows = workflow.jobs.enumerated()
            .sorted { (rank($0.element.status), $0.offset) < (rank($1.element.status), $1.offset) }
            .map { model(for: $0.element, of: workflow, link: link, review: review, words: words, now: now) }
        let isActive = PipelineStatePolicy.isActive(workflow.status) || workflow.status == .manual
        let isBusy = review.ciBusyWorkflows.contains(workflow.id)
        let failed = workflow.jobs.filter { $0.status == .failed }.count
        let running = workflow.jobs.filter { $0.status == .running }.count
        return PipelineJobGroupModel(
            id: "circleci:\(workflow.id)",
            title: workflow.name.isEmpty ? "CircleCI workflow" : workflow.name,
            icon: PullRequestTagMapper.pipelineIcon(workflow.status),
            tint: PullRequestTagMapper.pipelineTint(workflow.status),
            statusText: counts(failed: failed, running: running) ?? ciStatusText(workflow.status, words: words),
            jobs: rows,
            workflowID: workflow.id,
            sourceText: "CircleCI",
            canRerunFailed: isActive == false && failed > 0 && isBusy == false,
            canRerunAll: isActive == false && isBusy == false,
            canCancel: isActive && isBusy == false,
            isBusy: isBusy,
            rerunFailedHint: "Run the failed jobs of this workflow again (circleci workflow rerun --from-failed)",
            rerunAllHint: "Run the whole workflow again (circleci workflow rerun)",
            cancelHint: "Stop this workflow (circleci workflow cancel)"
        )
    }

    static func model(for job: CIJob, of workflow: CIWorkflow, link: CIWorkflowLink.Link?, review: PullRequestReviewState, words: CodeHostWords, now: Date) -> PipelineJobRowModel {
        let failedTests = review.ciFailedTests[job.id] ?? []
        let isDetailsOpen = review.openJobDetails.contains(job.id)
        let flakyCount = FlakyTestPolicy.flakyCount(of: failedTests, in: review.ciFlakyTests)
        let isBusy = review.ciBusyWorkflows.contains(workflow.id)
        let waitsForApproval = job.isApproval && job.status == .manual
        let isFinished = unfinishedStatuses.contains(job.status) == false && job.status != .manual
        let details = review.ciWorkflowDetails[workflow.id]
        let jobDetails = details?.job(job.id)
        let steps = review.ciJobSteps[job.id] ?? []
        let failedStep = steps.first(where: \.isFailed)
        let download = review.ciDownloads[job.id]
        return PipelineJobRowModel(
            id: job.id,
            jobID: job.id,
            title: job.name,
            icon: PullRequestTagMapper.pipelineIcon(job.status),
            tint: PullRequestTagMapper.pipelineTint(job.status),
            statusText: waitsForApproval ? "waiting for approval" : ciStatusText(job.status, words: words),
            durationText: jobDetails?.duration(now: now).map { DurationFormat.text($0) },
            allowedToFailText: nil,
            failureText: failedStep.map(stepFailureText),
            url: CIJobLink.url(base: link?.base, slug: details?.projectSlug ?? link?.slug, pipelineNumber: details?.pipelineNumber, workflowID: workflow.id, jobNumber: jobDetails?.number),
            canShowLog: isFinished && job.status != .skipped && job.isApproval == false,
            isLogOpen: review.openJobLogs.contains(job.id),
            log: review.jobLogs[job.id],
            logHint: circleCILogHint,
            canRetry: job.status == .failed && isBusy == false && PipelineStatePolicy.isActive(workflow.status) == false,
            retryHint: "Run the failed jobs of \(workflow.name) again (circleci workflow rerun --from-failed)",
            isBusy: isBusy,
            canApprove: waitsForApproval && workflow.runID != nil && isBusy == false,
            approveHint: "Approve this job: the jobs that wait for it start (circleci run approve)",
            noteText: nil,
            flakyTag: flakyTag(flakyCount: flakyCount, failedCount: failedTests.count),
            failedTests: failedTests.map { failedTest($0, jobID: job.id, flaky: review.ciFlakyTests, openMessages: review.openTestMessages) },
            detailsTitle: detailsTitle(failedTests: failedTests.count, failedStep: failedStep, steps: steps),
            detailsHint: detailsHint(isOpen: isDetailsOpen, failedTests: failedTests.count, hasSteps: steps.isEmpty == false),
            isDetailsOpen: isDetailsOpen,
            steps: steps.map(stepModel),
            canShowArtifacts: isFinished && job.status != .skipped && job.isApproval == false,
            isArtifactsOpen: review.openJobArtifacts.contains(job.id),
            artifacts: review.ciArtifacts[job.id].map(artifactsModel),
            downloadTitle: downloadTitle(download),
            downloadFolder: downloadFolder(download),
            downloadFailure: downloadFailure(download)
        )
    }

    static func failedTest(_ test: CITestResult, jobID: String, flaky: [CIFlakyTest], openMessages: Set<String>) -> PipelineJobRowModel.FailedTest {
        let id = "\(jobID)/\(test.className).\(test.name)"
        return PipelineJobRowModel.FailedTest(
            id: id,
            title: test.className.isEmpty ? test.name : "\(test.className).\(test.name)",
            message: test.message,
            flakyText: FlakyTestPolicy.match(test, in: flaky).map(flakyText),
            isMessageOpen: openMessages.contains(id)
        )
    }

    static func flakyText(_ flaky: CIFlakyTest) -> String {
        let text = "flaky · flaked \(CountText.count(flaky.timesFlaked, "time", "times"))"
        return flaky.source == .devhub ? "\(text) (DevHub)" : text
    }

    static func flakyTag(flakyCount: Int, failedCount: Int) -> TagModel? {
        guard flakyCount > 0 else { return nil }
        let allFlaky = flakyCount == failedCount
        let text = allFlaky ? "flaky" : "\(flakyCount) of \(failedCount) flaky"
        let hint = allFlaky
            ? (failedCount == 1 ? "The failed test is flaky: it passed on a re-run before (CircleCI Insights)" : "All \(failedCount) failed tests are flaky: they passed on a re-run before (CircleCI Insights)")
            : "\(flakyCount) of \(failedCount) failed tests are flaky: they passed on a re-run before (CircleCI Insights)"
        return TagModel(text, tint: .orange, systemImage: "shuffle", hint: hint)
    }

    static func stepFailureText(_ step: CIJobStep) -> String {
        guard let code = step.exitCode, code != 0 else { return "\(step.name) failed" }
        return "\(step.name) failed (exit \(code))"
    }

    static func stepModel(_ step: CIJobStep) -> PipelineJobRowModel.Step {
        PipelineJobRowModel.Step(
            id: step.index,
            title: step.name,
            icon: PullRequestTagMapper.pipelineIcon(step.status),
            tint: PullRequestTagMapper.pipelineTint(step.status),
            durationText: step.duration.map { DurationFormat.text($0) },
            exitText: step.exitCode.flatMap { $0 == 0 ? nil : "exit \($0)" }
        )
    }

    static func artifactsModel(_ state: CIArtifactsState) -> PipelineJobRowModel.Artifacts {
        switch state {
        case .loading: .loading
        case .failure(let message): .failure(message)
        case .loaded(let artifacts): .loaded(artifacts.map { PipelineJobRowModel.ArtifactRow(id: $0.id, path: $0.path, url: $0.url) })
        }
    }

    private static func detailsTitle(failedTests: Int, failedStep: CIJobStep?, steps: [CIJobStep]) -> String? {
        if failedTests > 0 { return CountText.count(failedTests, "failed test", "failed tests") }
        if failedStep != nil { return "reason" }
        return steps.isEmpty ? nil : "steps"
    }

    private static func detailsHint(isOpen: Bool, failedTests: Int, hasSteps: Bool) -> String {
        switch (failedTests > 0, hasSteps) {
        case (true, true): isOpen ? "Hide the steps and the failed tests" : "Show the failed step, the steps of this job and its failed tests"
        case (true, false): isOpen ? "Hide the failed tests" : "Show the failed tests of this job"
        default: isOpen ? "Hide the steps" : "Show the steps of this job and the one that failed"
        }
    }

    private static func downloadTitle(_ state: CIDownloadState?) -> String? {
        switch state {
        case nil, .failure: "Download All"
        case .downloading: "Downloading…"
        case .done: nil
        }
    }

    private static func downloadFolder(_ state: CIDownloadState?) -> String? {
        guard case .done(let folder) = state else { return nil }
        return folder
    }

    private static func downloadFailure(_ state: CIDownloadState?) -> String? {
        guard case .failure(let message) = state else { return nil }
        return message
    }

    private static func ciNote(for job: PipelineJob, review: PullRequestReviewState) -> String? {
        guard let workflowID = job.ciWorkflowID, review.hasCIProvider else { return nil }
        if let error = review.ciWorkflowErrors[workflowID] {
            return "CircleCI: \(error)"
        }
        guard let state = review.ciToolState else { return "Reading the CircleCI workflow…" }
        return CIPolicy.installCommand(for: state) == nil ? "Reading the CircleCI workflow…" : nil
    }

    static func ciStatusText(_ status: CheckStatus, words: CodeHostWords) -> String {
        status == .manual ? "on hold" : words.status(status)
    }

    private static func counts(for jobs: [PipelineJob]) -> String? {
        counts(
            failed: jobs.filter { $0.status == .failed && $0.allowsFailure == false }.count,
            running: jobs.filter { $0.status == .running }.count
        )
    }

    private static func counts(failed: Int, running: Int) -> String? {
        let parts = [failed > 0 ? "\(failed) failed" : nil, running > 0 ? "\(running) running" : nil].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func groupStatus(_ jobs: [PipelineJob]) -> CheckStatus {
        if jobs.contains(where: { $0.status == .failed && $0.allowsFailure == false }) { return .failed }
        if jobs.contains(where: { $0.status == .running }) { return .running }
        if jobs.contains(where: { [.pending, .created, .preparing, .waitingForResource, .scheduled].contains($0.status) }) { return .pending }
        if jobs.contains(where: { $0.status == .canceled }) { return .canceled }
        return .success
    }

    private static func rank(_ status: CheckStatus) -> Int {
        switch status {
        case .failed: 0
        case .running: 1
        case .canceled: 2
        case .pending, .created, .preparing, .waitingForResource, .scheduled, .manual: 3
        case .success: 5
        default: 4
        }
    }
}
