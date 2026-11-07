import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class CIBranchRunsStore {
    private(set) var run: CIRun?
    private(set) var workflows: [CIWorkflow] = []
    private(set) var error: String?
    private(set) var isLoading = false
    private(set) var loadedBranch: String?
    private(set) var busyWorkflows: Set<String> = []
    private(set) var baseRun: CIRun?
    private(set) var baseWorkflows: [CIWorkflow] = []
    private(set) var baseBranch: String?

    @ObservationIgnored private let ci: any CIRepository
    @ObservationIgnored private let projects: CIProjectResolver
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private let basePollInterval: Duration
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var loadedAt: [String: Date] = [:]
    @ObservationIgnored private var isPolling = false
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var loggedError: String?
    @ObservationIgnored private var loggedBaseError: String?
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let staleAfter: TimeInterval = 90

    init(
        ci: any CIRepository,
        projects: CIProjectResolver,
        checkout: any CheckoutContext,
        activity: ActivityLog,
        operations: OperationLog,
        notifier: Notifier,
        events: AppEvents,
        basePollInterval: Duration
    ) {
        self.ci = ci
        self.projects = projects
        self.checkout = checkout
        self.activity = activity
        self.operations = operations
        self.notifier = notifier
        self.basePollInterval = basePollInterval
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                reset()
                resumePolling()
            case .pullRequestsChanged, .refreshRequested(.git):
                guard loadedBranch != nil else { return }
                Task { await self.refresh() }
            default:
                break
            }
        }
    }

    var isAvailable: Bool {
        projects.provider != nil
    }

    var slug: String? {
        project.slug
    }

    var baseFailure: BaseBranchCIFailure? {
        guard let baseRun, baseRun.status == .failed, let baseBranch else { return nil }
        return BaseBranchCIFailure(branch: baseBranch, workflows: baseWorkflows.filter { $0.status == .failed }.map(\.name), subject: baseRun.subject)
    }

    private var project: CIProject {
        projects.project(for: [])
    }

    // MARK: Current branch

    func refreshIfStale() async {
        guard let branch = checkout.currentBranch else { return }
        if branch == loadedBranch, let date = loadedAt[branch], date.timeIntervalSinceNow > -Self.staleAfter { return }
        await refresh()
    }

    func refresh() async {
        guard isAvailable, let branch = checkout.currentBranch else { return }
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer {
                if Task.isCancelled == false {
                    isLoading = false
                }
            }
            if loadedBranch != branch {
                run = nil
                workflows = []
            }
            do {
                let (latest, loaded) = try await read(branch: branch)
                try Task.checkCancellation()
                run = latest
                workflows = loaded
                error = nil
                loggedError = nil
            } catch is CancellationError {
                return
            } catch {
                try Task.checkCancellation()
                self.error = error.localizedDescription
                report(error, title: "Cannot read the CircleCI runs of \(branch)", logged: &loggedError)
            }
            loadedBranch = branch
            loadedAt[branch] = .now
        }
    }

    func rerun(_ workflowID: String, named name: String) {
        perform(workflowID, action: "Re-run failed jobs", title: "Re-ran the failed jobs of \(name)") { [ci] project in
            try await ci.rerun(workflowID: workflowID, fromFailed: true, project: project)
        }
    }

    func cancel(_ workflowID: String, named name: String) {
        perform(workflowID, action: "Cancel workflow", title: "Cancelled \(name)") { [ci] project in
            try await ci.cancel(workflowID: workflowID, project: project)
        }
    }

    private func perform(_ workflowID: String, action: String, title: String, _ work: @escaping @Sendable (CIProject) async throws -> Void) {
        guard busyWorkflows.contains(workflowID) == false else { return }
        busyWorkflows.insert(workflowID)
        let project = project
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform(action, at: .git, retry: nil) {
                    try await work(project)
                }
                activity.log(title, detail: "", outcome: .success)
            } catch {
                activity.log("\(title.replacingOccurrences(of: "Re-ran", with: "Re-run of")) failed", detail: error.localizedDescription, outcome: .failure)
            }
            busyWorkflows.remove(workflowID)
            loadedAt = [:]
            await refresh()
        }
    }

    // MARK: Base branch

    func startPolling() {
        isPolling = true
        resumePolling()
    }

    func checkBase() async -> Bool {
        guard isAvailable else { return true }
        let branch = checkout.baseName
        do {
            let (latest, loaded) = try await read(branch: branch)
            loggedBaseError = nil
            apply(base: latest, workflows: loaded, branch: branch)
            return true
        } catch is CancellationError {
            return false
        } catch CIError.notInstalled {
            report(CIError.notInstalled, title: "Cannot watch the CI of \(branch)", logged: &loggedBaseError)
            return false
        } catch CIError.notLoggedIn {
            report(CIError.notLoggedIn, title: "Cannot watch the CI of \(branch)", logged: &loggedBaseError)
            return false
        } catch let failure as CIError {
            report(failure, title: "Cannot watch the CI of \(branch)", logged: &loggedBaseError)
            if case .oldVersion = failure { return false }
            return true
        } catch {
            report(error, title: "Cannot watch the CI of \(branch)", logged: &loggedBaseError)
            return true
        }
    }

    private func apply(base latest: CIRun?, workflows loaded: [CIWorkflow], branch: String) {
        let previous = baseRun
        if baseRun != latest {
            baseRun = latest
        }
        if baseWorkflows != loaded {
            baseWorkflows = loaded
        }
        if baseBranch != branch {
            baseBranch = branch
        }
        guard let latest, latest.status == .failed, let previous, previous.id != latest.id || previous.status != .failed else { return }
        let failure = BaseBranchCIFailure(branch: branch, workflows: loaded.filter { $0.status == .failed }.map(\.name), subject: latest.subject)
        activity.log(failure.title, detail: failure.subject ?? "", outcome: .failure, kind: .baseBranchChecks, target: .git)
        notifier.notify(.baseBranchChecks, title: failure.title, body: failure.subject, target: .git)
    }

    private func resumePolling() {
        guard isPolling, pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while Task.isCancelled == false {
                guard let self else { return }
                guard await checkBase() else {
                    pollingTask = nil
                    return
                }
                try? await Task.sleep(for: basePollInterval)
            }
        }
    }

    // MARK: Shared

    private func read(branch: String) async throws -> (CIRun?, [CIWorkflow]) {
        let project = project
        guard let latest = try await ci.branchRuns(branch: branch, limit: 1, project: project).first else { return (nil, []) }
        return (latest, try await ci.workflows(runID: latest.id, project: project))
    }

    private func report(_ error: Error, title: String, logged: inout String?) {
        let message = error.localizedDescription
        guard logged != message else { return }
        logged = message
        activity.log(title, detail: message, outcome: .failure)
    }

    private func reset() {
        pollingTask?.cancel()
        pollingTask = nil
        run = nil
        workflows = []
        error = nil
        loadedBranch = nil
        loadedAt = [:]
        busyWorkflows = []
        baseRun = nil
        baseWorkflows = []
        baseBranch = nil
        loggedError = nil
        loggedBaseError = nil
    }
}
