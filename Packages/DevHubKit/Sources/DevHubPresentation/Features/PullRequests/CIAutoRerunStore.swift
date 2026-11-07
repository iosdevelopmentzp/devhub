import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class CIAutoRerunStore: CIAutoRerunLookup {
    private(set) var plans: [Int: CIAutoRerunPlan] = [:]
    private(set) var onlyFlaky = true

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let ci: any CIRepository
    @ObservationIgnored private let projects: CIProjectResolver
    @ObservationIgnored private let history: CIWorkflowHistory
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var isPolling = false
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var checking: Set<Int> = []
    @ObservationIgnored private var loggedErrors: [Int: String] = [:]
    @ObservationIgnored private var loggedFlakyError: String?
    @ObservationIgnored private var flakyCache: FlakyCache?
    @ObservationIgnored private var subscription: SubscriptionToken?

    static let pollInterval: Duration = .seconds(60)
    static let flakyListAge: TimeInterval = 600
    private static let failedTestJobLimit = 5

    init(
        repository: CodeHostRepository,
        ci: any CIRepository,
        projects: CIProjectResolver,
        history: CIWorkflowHistory,
        remote: any CodeHostLookup,
        session: ProjectSession,
        activity: ActivityLog,
        notifier: Notifier,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.repository = repository
        self.ci = ci
        self.projects = projects
        self.history = history
        self.remote = remote
        self.session = session
        self.activity = activity
        self.notifier = notifier
        self.events = events
        self.store = store
        plans = Self.loadPlans(from: store, projectID: session.selectedProjectID)
        onlyFlaky = Self.loadOnlyFlaky(from: store, projectID: session.selectedProjectID)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            pollingTask?.cancel()
            pollingTask = nil
            loggedErrors = [:]
            loggedFlakyError = nil
            flakyCache = nil
            plans = Self.loadPlans(from: store, projectID: session.selectedProjectID)
            onlyFlaky = Self.loadOnlyFlaky(from: store, projectID: session.selectedProjectID)
            resumePolling()
        }
    }

    var words: CodeHostWords {
        remote.words
    }

    func plan(for iid: Int) -> CIAutoRerunPlan? {
        plans[iid]
    }

    func startPolling() {
        isPolling = true
        resumePolling()
    }

    func setOnlyFlaky(_ enabled: Bool) {
        guard enabled != onlyFlaky else { return }
        onlyFlaky = enabled
        store.set(enabled ? nil : "any", forKey: PullRequestsPreferenceKeys.autoRerunOnlyFlaky(projectID: session.selectedProjectID))
        activity.log(enabled ? "Auto re-run: only flaky failures" : "Auto re-run: every failure", detail: Self.modeText(onlyFlaky: enabled), outcome: .info)
    }

    func start(_ iid: Int, maxAttempts: Int) {
        guard plans[iid] == nil, maxAttempts > 0 else { return }
        plans[iid] = CIAutoRerunPlan(iid: iid, maxAttempts: maxAttempts, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil, onlyFlaky: onlyFlaky)
        save()
        activity.log(
            "Auto re-run on for \(words.reference(iid))",
            detail: "DevHub runs the failed CircleCI jobs again each time a workflow fails, up to \(CountText.count(maxAttempts, "time", "times")). \(Self.modeText(onlyFlaky: onlyFlaky))",
            outcome: .info
        )
        resumePolling()
        Task { await self.check(iid) }
    }

    func stop(_ iid: Int) {
        guard plans[iid] != nil else { return }
        plans[iid] = nil
        loggedErrors[iid] = nil
        save()
        activity.log("Auto re-run off for \(words.reference(iid))", detail: "", outcome: .info)
    }

    func check(_ iid: Int) async {
        guard plans[iid] != nil, checking.contains(iid) == false else { return }
        checking.insert(iid)
        defer { checking.remove(iid) }
        do {
            let url = try await remote.codeHost()
            let details = try await repository.details(iid: iid, repository: url)
            guard projects.hasProvider(for: details.jobs) else { return }
            let project = projects.project(for: details.jobs)
            var workflows: [CIWorkflow] = []
            for workflowID in CIPolicy.workflowIDs(of: details.jobs) {
                workflows.append(try await ci.workflow(id: workflowID, project: project))
            }
            loggedErrors[iid] = nil
            await act(on: workflows, of: iid, project: project)
        } catch is CancellationError {
        } catch {
            report(error, of: iid)
        }
    }

    private func act(on workflows: [CIWorkflow], of iid: Int, project: CIProject) async {
        guard let plan = plans[iid] else { return }
        let reference = words.reference(iid)
        var testsByWorkflow: [String: [String: [CITestResult]]] = [:]
        var decisions: [CIAutoRerunPolicy.Decision] = []
        for workflow in workflows {
            var failure: CIFailureKind?
            if plan.onlyFlaky, workflow.status == .failed, plan.handledWorkflowIDs.contains(workflow.id) == false {
                let tests = await failedTests(of: workflow, project: project)
                testsByWorkflow[workflow.id] = tests
                failure = CIFailurePolicy.kind(of: workflow, failedTests: tests, flaky: FlakyTrackingPolicy.merged(insights: await flakyTests(project: project), ledger: history.flakyTests))
            }
            decisions.append(CIAutoRerunPolicy.decision(for: workflow, plan: plan, failure: failure, now: .now))
        }
        switch CIAutoRerunPolicy.outcome(of: decisions) {
        case .wait:
            break
        case .rerun:
            let failed = zip(workflows, decisions).filter { $0.1 == .rerun }.map(\.0)
            await rerun(failed, of: iid, project: project, failedTests: testsByWorkflow)
        case .succeeded:
            finish(iid, title: "\(words.checksTitle) of \(reference) passed", body: afterText(plan.attempts), outcome: .success)
        case .cancelled:
            finish(iid, title: "Auto re-run of \(reference) stopped", body: "A CircleCI workflow was cancelled", outcome: .info)
        case .exhausted:
            finish(iid, title: "Auto re-run of \(reference) gave up", body: "The \(words.checks) failed again after \(CountText.count(plan.maxAttempts, "re-run", "re-runs"))", outcome: .failure)
        case .stopped(let reason):
            for (workflow, decision) in zip(workflows, decisions) {
                guard case .stopped = decision else { continue }
                history.remember(workflow, failedTests: testsByWorkflow[workflow.id] ?? [:], for: iid)
            }
            finish(iid, title: "Auto re-run of \(reference) stopped", body: "No re-run: \(reason)", outcome: .failure)
        }
    }

    private func rerun(_ workflows: [CIWorkflow], of iid: Int, project: CIProject, failedTests: [String: [String: [CITestResult]]]) async {
        let reference = words.reference(iid)
        var didRerun = false
        for workflow in workflows {
            guard let plan = plans[iid], plan.attempts < plan.maxAttempts else { break }
            let tests: [String: [CITestResult]]
            if let known = failedTests[workflow.id] {
                tests = known
            } else {
                tests = await self.failedTests(of: workflow, project: project)
            }
            history.remember(workflow, failedTests: tests, for: iid)
            do {
                try await ci.rerun(workflowID: workflow.id, fromFailed: true, project: project)
            } catch {
                report(error, of: iid)
                continue
            }
            guard var updated = plans[iid] else { break }
            updated.attempts += 1
            updated.handledWorkflowIDs.insert(workflow.id)
            updated.lastRerunAt = .now
            plans[iid] = updated
            save()
            didRerun = true
            let title = "Re-run \(updated.attempts) of \(updated.maxAttempts): \(workflow.name) of \(reference)"
            activity.log(title, detail: "The failed jobs run again (circleci workflow rerun --from-failed)", outcome: .info, kind: .requestChecks, target: .pullRequest(iid: iid))
            notifier.notify(.requestChecks, title: title, body: nil, target: .pullRequest(iid: iid))
        }
        if didRerun {
            events.post(.pullRequestChecksChanged(iid: iid))
        }
    }

    private func failedTests(of workflow: CIWorkflow, project: CIProject) async -> [String: [CITestResult]] {
        var failedTests: [String: [CITestResult]] = [:]
        for job in workflow.jobs.filter({ $0.status == .failed }).prefix(Self.failedTestJobLimit) {
            do {
                failedTests[job.id] = try await ci.failedTests(jobID: job.id, project: project)
            } catch {
                activity.log("Cannot read the failed tests of \(job.name)", detail: error.localizedDescription, outcome: .failure)
            }
        }
        return failedTests
    }

    private func flakyTests(project: CIProject) async -> [CIFlakyTest] {
        if let flakyCache, Date.now.timeIntervalSince(flakyCache.readAt) < Self.flakyListAge {
            return flakyCache.tests
        }
        var tests: [CIFlakyTest] = []
        do {
            tests = try await ci.flakyTests(project: project)
            loggedFlakyError = nil
        } catch {
            let message = error.localizedDescription
            if message != loggedFlakyError {
                loggedFlakyError = message
                activity.log("Cannot read the flaky tests of CircleCI", detail: message, outcome: .failure)
            }
        }
        flakyCache = FlakyCache(tests: tests, readAt: .now)
        return tests
    }

    static func modeText(onlyFlaky: Bool) -> String {
        onlyFlaky
            ? "A re-run happens only when every failed test is flaky. A failure on another test or without test results stops the plan"
            : "A re-run happens after every failure"
    }

    private func finish(_ iid: Int, title: String, body: String, outcome: ActivityEvent.Outcome) {
        plans[iid] = nil
        loggedErrors[iid] = nil
        save()
        activity.log(title, detail: body, outcome: outcome, kind: .requestChecks, target: .pullRequest(iid: iid))
        notifier.notify(.requestChecks, title: title, body: body, target: .pullRequest(iid: iid))
    }

    private func report(_ error: Error, of iid: Int) {
        let message = error.localizedDescription
        guard loggedErrors[iid] != message else { return }
        loggedErrors[iid] = message
        activity.log("Auto re-run of \(words.reference(iid)) cannot read the \(words.checks)", detail: message, outcome: .failure)
    }

    private func afterText(_ attempts: Int) -> String {
        attempts == 0 ? "No re-run was needed" : "After \(CountText.count(attempts, "re-run", "re-runs")) of the failed jobs"
    }

    private func resumePolling() {
        guard isPolling, pollingTask == nil, plans.isEmpty == false else { return }
        pollingTask = Task { [weak self] in
            while Task.isCancelled == false {
                guard let self else { return }
                guard plans.isEmpty == false else {
                    pollingTask = nil
                    return
                }
                for iid in plans.keys.sorted() {
                    await check(iid)
                }
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    private func save() {
        let kept = plans.values.sorted { $0.iid < $1.iid }
        store.encode(kept.isEmpty ? nil : kept, forKey: PullRequestsPreferenceKeys.autoRerun(projectID: session.selectedProjectID))
    }

    private static func loadOnlyFlaky(from store: any KeyValueStore, projectID: String) -> Bool {
        store.string(forKey: PullRequestsPreferenceKeys.autoRerunOnlyFlaky(projectID: projectID)) != "any"
    }

    private static func loadPlans(from store: any KeyValueStore, projectID: String) -> [Int: CIAutoRerunPlan] {
        let plans = store.decode([CIAutoRerunPlan].self, forKey: PullRequestsPreferenceKeys.autoRerun(projectID: projectID)) ?? []
        return Dictionary(plans.map { ($0.iid, $0) }, uniquingKeysWith: { first, _ in first })
    }
}

private struct FlakyCache {
    let tests: [CIFlakyTest]
    let readAt: Date
}
