import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class TestRunsStore {
    private(set) var runs: [Worktree.ID: TestRun] = [:]

    @ObservationIgnored private let runTests: RunTestsUseCase
    @ObservationIgnored private let tests: any TestRunRepository
    @ObservationIgnored private let build: any BuildLookup
    @ObservationIgnored private let worktrees: any WorktreeLookup
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private let prompts: any ReviewPromptRepository
    @ObservationIgnored private var tasks: [Worktree.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var subscription: SubscriptionToken?

    static let failureLimit = 200

    init(
        runTests: RunTestsUseCase,
        tests: any TestRunRepository,
        build: any BuildLookup,
        worktrees: any WorktreeLookup,
        config: ConfigStore,
        activity: ActivityLog,
        notifier: Notifier,
        events: AppEvents,
        prompts: any ReviewPromptRepository
    ) {
        self.runTests = runTests
        self.tests = tests
        self.build = build
        self.worktrees = worktrees
        self.config = config
        self.activity = activity
        self.notifier = notifier
        self.prompts = prompts
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                cancelAll()
                runs = [:]
            case .worktreesChanged:
                dropRunsOfRemovedWorktrees()
            default:
                break
            }
        }
    }

    func isRunning(_ id: Worktree.ID) -> Bool {
        runs[id]?.isRunning == true
    }

    func run(worktreeID id: Worktree.ID) {
        start(worktreeID: id, onlyTests: [])
    }

    func runFailedAgain(worktreeID id: Worktree.ID) {
        guard let run = runs[id], run.isRunning == false else { return }
        let onlyTests = TestResultsPolicy.onlyTests(run.cases)
        guard onlyTests.isEmpty == false else { return }
        start(worktreeID: id, onlyTests: onlyTests)
    }

    private func start(worktreeID id: Worktree.ID, onlyTests: [String]) {
        guard tasks[id] == nil, let worktree = worktrees.worktree(atPath: id), worktree.isMissing == false else { return }
        guard let simulator = build.target else {
            activity.log("No simulator for the tests", detail: "Choose a target simulator in the Simulators tab first.", outcome: .failure)
            return
        }
        let request = TestRunRequest(
            projectPath: worktree.path,
            container: config.resolved.project.xcode?.container,
            scheme: build.selectedScheme,
            configuration: build.selectedConfiguration,
            simulatorUDID: simulator.id,
            simulatorName: simulator.name,
            onlyTests: onlyTests
        )
        runs[id] = TestRun(scheme: request.scheme, simulatorName: simulator.name, startedAt: .now, phase: .running(step: "Preparing"), onlyTests: onlyTests)
        tasks[id] = Task { [weak self] in
            guard let self else { return }
            do {
                for try await event in runTests.run(request) {
                    handle(event, for: id)
                }
                try Task.checkCancellation()
                await readBundle(for: id, worktree: worktree)
                try Task.checkCancellation()
                reportOutcome(for: id, worktree: worktree)
            } catch is CancellationError {
                runs[id] = nil
                activity.log("Tests cancelled", detail: "\(worktree.displayName) · \(request.scheme)", outcome: .info, kind: .tests, target: .worktree(path: worktree.path))
            } catch {
                runs[id]?.phase = .notRun(error.localizedDescription, .now)
                activity.log("Tests did not run: \(worktree.displayName)", detail: error.localizedDescription, outcome: .failure, kind: .tests, target: .worktree(path: worktree.path))
                notifier.notify(.tests, title: "Tests did not run: \(worktree.displayName)", body: error.localizedDescription, target: .worktree(path: worktree.path))
            }
            tasks[id] = nil
        }
    }

    func writeFixPrompt(worktreeID id: Worktree.ID) async -> String? {
        guard let run = runs[id], run.isRunning == false, let worktree = worktrees.worktree(atPath: id) else { return nil }
        guard run.failures.isEmpty == false || run.issues.isEmpty == false else {
            activity.log("Nothing to fix in \(worktree.displayName)", detail: "The last run has no failed test and no compiler error.", outcome: .info)
            return nil
        }
        let prompt = FixPromptBuilder.tests(scheme: run.scheme, checkoutName: worktree.displayName, passed: run.passed, failed: run.failed, skipped: run.skipped, failures: run.failures, issues: run.issues)
        do {
            return try await prompts.save(prompt, name: FixPromptBuilder.fileName(forTestsOf: worktree.displayName))
        } catch {
            activity.log("Cannot write the fix prompt of \(worktree.displayName)", detail: error.localizedDescription, outcome: .failure)
            return nil
        }
    }

    func cancel(worktreeID id: Worktree.ID) {
        tasks[id]?.cancel()
    }

    func dismiss(worktreeID id: Worktree.ID) {
        guard isRunning(id) == false else { return }
        runs[id] = nil
    }

    // MARK: Private

    private func handle(_ event: TestEvent, for id: Worktree.ID) {
        guard var run = runs[id] else { return }
        switch event {
        case .step(let step):
            run.phase = .running(step: step)
        case .output:
            return
        case .issue(let issue):
            guard run.issues.count < Self.failureLimit, run.issues.contains(issue) == false else { return }
            run.issues.append(issue)
        case .testFinished(let result):
            switch result.status {
            case .passed: run.passed += 1
            case .failed: run.failed += 1
            case .skipped: run.skipped += 1
            }
        case .failure(let failure):
            guard run.failures.count < Self.failureLimit, run.failures.contains(failure) == false else { return }
            run.failures.append(failure)
        case .finished(let report):
            run.phase = .finished(report.status, .now)
            run.resultBundlePath = report.resultBundlePath
        }
        runs[id] = run
    }

    private func readBundle(for id: Worktree.ID, worktree: Worktree) async {
        guard let bundle = runs[id]?.resultBundlePath else { return }
        let cases: [TestResultCase]
        do {
            cases = try await tests.results(bundlePath: bundle, projectPath: worktree.path)
        } catch {
            activity.log("Cannot read the test results of \(worktree.displayName)", detail: error.localizedDescription, outcome: .failure)
            return
        }
        guard cases.isEmpty == false, var run = runs[id] else { return }
        run.cases = cases
        run.passed = cases.filter { $0.status == .passed }.count
        run.failed = cases.filter { $0.status == .failed }.count
        run.skipped = cases.filter { $0.status == .skipped }.count
        let failures = TestResultsPolicy.failures(cases)
        if failures.isEmpty == false {
            run.failures = Array(failures.prefix(Self.failureLimit))
        }
        runs[id] = run
        guard failures.isEmpty == false else { return }
        do {
            let failedIDs = Set(TestResultsPolicy.failed(cases).map(\.identifier))
            let attachments = try await tests.exportAttachments(bundlePath: bundle)
            runs[id]?.attachments = attachments.filter { failedIDs.contains($0.testIdentifier) }
        } catch {
            activity.log("Cannot read the test attachments of \(worktree.displayName)", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func reportOutcome(for id: Worktree.ID, worktree: Worktree) {
        guard let run = runs[id], case .finished(let status, _) = run.phase else { return }
        let counts = TestRunText.counts(passed: run.passed, failed: run.failed, skipped: run.skipped)
        let detail = "\(counts) · \(run.scheme) · \(run.simulatorName)"
        let title = status == .passed ? "Tests passed: \(worktree.displayName)" : "Tests failed: \(worktree.displayName)"
        activity.log(title, detail: detail, outcome: status == .passed ? .success : .failure, kind: .tests, target: .worktree(path: worktree.path))
        notifier.notify(.tests, title: title, body: counts, target: .worktree(path: worktree.path))
    }

    private func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks = [:]
    }

    private func dropRunsOfRemovedWorktrees() {
        guard worktrees.worktrees.isEmpty == false else { return }
        for id in runs.keys where worktrees.worktree(atPath: id) == nil && tasks[id] == nil {
            runs[id] = nil
        }
    }
}
