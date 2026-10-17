import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class NewPullRequestStore {
    var draft: NewPullRequestDraft?

    @ObservationIgnored private let git: any GitRepository
    @ObservationIgnored private let codeHost: any CodeHostRepository
    @ObservationIgnored private let createPullRequest: CreatePullRequestUseCase
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private var subscription: SubscriptionToken?

    var words: CodeHostWords {
        remote.words
    }

    init(
        git: any GitRepository,
        codeHost: any CodeHostRepository,
        createPullRequest: CreatePullRequestUseCase,
        checkout: any CheckoutContext,
        remote: any CodeHostLookup,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.git = git
        self.codeHost = codeHost
        self.createPullRequest = createPullRequest
        self.checkout = checkout
        self.remote = remote
        self.activity = activity
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            draft = nil
        }
    }

    func open(branch: String, origin: NewPullRequestDraft.Origin) async {
        let settings = checkout.gitSettings.pullRequests
        let targets = checkout.pullRequestTargets(for: branch)
        let local = checkout.localBranch(named: branch)
        let target = targets.first ?? checkout.baseName
        draft = NewPullRequestDraft(
            origin: origin,
            sourceBranch: branch,
            targets: targets,
            targetBranch: target,
            title: NewPullRequestMapper.title(branch: branch, lastSubject: nil, ticket: checkout.gitSettings.ticket(fallbackURL: "")),
            description: "",
            availableLabels: [],
            labels: [],
            isDraft: settings.isDraft,
            removeSourceBranch: settings.deleteSourceBranch,
            squash: settings.squash,
            pushPlan: CreatePullRequestUseCase.pushPlan(upstream: local?.upstream, ahead: local?.ahead ?? 0, isCurrent: branch == checkout.currentBranch),
            isLoading: true,
            isCreating: false,
            error: nil
        )
        let path = checkout.checkoutPath
        let targetRef = BranchName(target, remote: remote.remoteName).remoteRef
        async let subjects = try? git.commitSubjects(from: targetRef, to: branch, in: path)
        let kind = (try? await remote.codeHost())?.kind
        async let template = git.pullRequestTemplate(in: path, file: GitSettingsPolicy.templatePath(settings, kind: kind))
        async let labels = loadLabels()
        let (loadedSubjects, loadedTemplate, loadedLabels) = await (subjects ?? [], template, labels)
        guard draft?.sourceBranch == branch, draft?.origin == origin else { return }
        draft?.title = NewPullRequestMapper.title(branch: branch, lastSubject: loadedSubjects.first, ticket: checkout.gitSettings.ticket(fallbackURL: ""))
        draft?.description = NewPullRequestMapper.description(template: loadedTemplate, branch: branch, subjects: loadedSubjects, ticket: checkout.gitSettings.ticket(fallbackURL: ""))
        switch loadedLabels {
        case .success(let names):
            draft?.availableLabels = names
        case .failure(let error):
            draft?.error = "Cannot read the labels: \(error.localizedDescription)"
        }
        draft?.isLoading = false
    }

    func cancel() {
        draft = nil
    }

    func toggleLabel(_ name: String) {
        guard draft != nil else { return }
        if draft?.labels.contains(name) == true {
            draft?.labels.remove(name)
        } else {
            draft?.labels.insert(name)
        }
    }

    func create() async -> PullRequestSummary.ID? {
        guard let current = draft, current.isCreating == false else { return nil }
        draft?.isCreating = true
        draft?.error = nil
        do {
            let url = try await remote.codeHost()
            let created = try await createPullRequest.execute(current.request, push: current.pushPlan, remote: remote.remoteName, checkoutPath: checkout.checkoutPath, repository: url)
            activity.log("Created \(remote.words.reference(created.iid))", detail: created.title, outcome: .success)
            if current.pushPlan != .none {
                events.post(.branchesChanged)
            }
            events.post(.pullRequestsChanged)
            draft = nil
            return created.iid
        } catch {
            activity.log("Cannot create the \(remote.words.request)", detail: error.localizedDescription, outcome: .failure)
            draft?.isCreating = false
            draft?.error = error.localizedDescription
            return nil
        }
    }

    private func loadLabels() async -> Result<[String], any Error> {
        do {
            return .success(try await codeHost.labels(repository: try await remote.codeHost()))
        } catch {
            return .failure(error)
        }
    }
}
