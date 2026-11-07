import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class AITextStore {
    private(set) var running: Set<AITextTarget> = []
    private(set) var explanations: [Int: String] = [:]

    @ObservationIgnored private let repository: any AITextRepository
    @ObservationIgnored private let changes: any GitChangesRepository
    @ObservationIgnored private let git: any GitRepository
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private var tasks: [AITextTarget: Task<Void, Never>] = [:]
    @ObservationIgnored private var subscription: SubscriptionToken?

    static let recentSubjectRange = "HEAD~15"

    init(
        repository: any AITextRepository,
        changes: any GitChangesRepository,
        git: any GitRepository,
        checkout: any CheckoutContext,
        remote: any CodeHostLookup,
        settings: SettingsStore,
        operations: OperationLog,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.repository = repository
        self.changes = changes
        self.git = git
        self.checkout = checkout
        self.remote = remote
        self.settings = settings
        self.operations = operations
        self.activity = activity
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            explanations = [:]
        }
    }

    var defaultProvider: AIProvider {
        settings.values.aiTextProvider
    }

    var explainingIDs: Set<Int> {
        Set(running.compactMap { target in
            guard case .explain(let iid) = target else { return nil }
            return iid
        })
    }

    func isRunning(_ target: AITextTarget) -> Bool {
        running.contains(target)
    }

    func stop(_ target: AITextTarget) {
        tasks[target]?.cancel()
    }

    func writeCommitMessage(provider: AIProvider, onText: @escaping (String) -> Void) {
        let path = checkout.checkoutPath
        let branch = checkout.currentBranch
        run(.commitMessage(path: path), title: "Write a commit message", origin: .changes, provider: provider, cwd: path) { [changes, git] in
            let patch = try await changes.patch(.staged, in: path)
            guard patch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { throw AITextError.nothingToDescribe }
            let subjects = (try? await git.commitSubjects(from: Self.recentSubjectRange, to: "HEAD", in: path)) ?? []
            return AITextPromptBuilder.commitMessage(patch: patch, recentSubjects: subjects, branch: branch)
        } done: { answer in
            onText(AITextAnswerParser.clean(answer))
        }
    }

    func writePullRequest(_ draft: NewPullRequestDraft, provider: AIProvider, onText: @escaping (String, String) -> Void) {
        let path = checkout.checkoutPath
        let base = BranchName(draft.targetBranch, remote: remote.remoteName).remoteRef
        let noun = remote.words.request
        run(.newRequest(branch: draft.sourceBranch), title: "Write the \(noun)", origin: .newPullRequest, provider: provider, cwd: path) { [changes, git] in
            let patch = try await changes.patch(.range(base: base, head: draft.sourceBranch), in: path)
            guard patch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { throw AITextError.nothingToDescribe }
            let commits = (try? await git.commitSubjects(from: base, to: draft.sourceBranch, in: path)) ?? []
            return AITextPromptBuilder.pullRequest(patch: patch, commits: commits, template: draft.description, currentTitle: draft.title, source: draft.sourceBranch, target: draft.targetBranch, noun: noun)
        } done: { answer in
            let parts = AITextAnswerParser.titleAndBody(answer)
            onText(parts.title, parts.body)
        }
    }

    func explain(_ summary: PullRequestSummary, description: String, files: [PullRequestFileDiff], changedSinceReview: [String], provider: AIProvider) {
        let id = summary.id
        let noun = remote.words.request
        let plan = ExplainPartsPolicy.plan(files, limit: AITextPromptBuilder.patchLimit)
        let steps: [() async throws -> String] = plan.parts.isEmpty
            ? [{ throw AITextError.nothingToDescribe }]
            : plan.parts.enumerated().map { index, part in
                { AITextPromptBuilder.explain(title: summary.title, description: description, files: part, changedSinceReview: changedSinceReview, noun: noun, part: index + 1, of: plan.parts.count) }
            }
        run(.explain(iid: id), title: "Explain \(remote.words.reference(id))", origin: .pullRequest(id), provider: provider, cwd: checkout.checkoutPath, steps: steps) { [weak self] answers in
            self?.explanations[id] = ExplainPartsPolicy.joined(answers.map(AITextAnswerParser.clean), leftOut: plan.leftOut)
        }
    }

    func clearExplanation(of id: Int) {
        explanations[id] = nil
    }

    private func run(
        _ target: AITextTarget,
        title: String,
        origin: OperationOrigin,
        provider: AIProvider,
        cwd: String,
        prompt: @escaping () async throws -> String,
        done: @escaping (String) -> Void
    ) {
        run(target, title: title, origin: origin, provider: provider, cwd: cwd, steps: [prompt]) { answers in
            done(answers.last ?? "")
        }
    }

    private func run(
        _ target: AITextTarget,
        title: String,
        origin: OperationOrigin,
        provider: AIProvider,
        cwd: String,
        steps: [() async throws -> String],
        done: @escaping ([String]) -> Void
    ) {
        guard running.contains(target) == false else { return }
        let command = checkout.gitSettings.pullRequests.aiTextCommands[provider] ?? ""
        let tool = AISessionRowMapper.toolTitle(for: provider)
        let fullTitle = "\(title) with \(tool)"
        let id = operations.start(fullTitle, at: origin, retry: nil, stop: { [weak self] in
            guard let self else { return }
            stop(target)
        })
        operations.setProgress(of: id, text: "\(tool) is writing…", fraction: nil)
        running.insert(target)
        tasks[target] = Task { [weak self] in
            guard let self else { return }
            do {
                var answers: [String] = []
                for (index, step) in steps.enumerated() {
                    if steps.count > 1 {
                        operations.setProgress(of: id, text: "Reading part \(index + 1) of \(steps.count)…", fraction: Double(index) / Double(steps.count))
                    }
                    let answer = try await OperationScope.$current.withValue(id) {
                        try await repository.generate(prompt: step(), command: command, cwd: cwd)
                    }
                    try Task.checkCancellation()
                    answers.append(answer)
                }
                operations.succeed(id)
                activity.log(fullTitle, detail: steps.count > 1 ? CountText.count(steps.count, "part") : "", outcome: .success)
                done(answers)
            } catch is CancellationError {
                operations.cancel(id)
                activity.log("\(fullTitle) stopped", detail: "", outcome: .info)
            } catch {
                operations.fail(id, message: error.localizedDescription)
                activity.log("\(fullTitle) failed", detail: error.localizedDescription, outcome: .failure)
            }
            running.remove(target)
            tasks[target] = nil
        }
    }
}
