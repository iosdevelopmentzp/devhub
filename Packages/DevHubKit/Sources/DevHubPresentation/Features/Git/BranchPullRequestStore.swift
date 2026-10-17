import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class BranchPullRequestStore {
    private(set) var status: PullRequestStatus?
    private(set) var error: PullRequestError?
    private(set) var isLoading = false
    private(set) var loadedBranch: String?

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private var loadedAt: [String: Date] = [:]
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private let refreshTask = RefreshTask()

    init(repository: CodeHostRepository, checkout: any CheckoutContext, events: AppEvents) {
        self.repository = repository
        self.checkout = checkout
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            status = nil
            error = nil
            loadedBranch = nil
            loadedAt = [:]
        }
    }

    func refreshIfStale() async {
        guard let branch = checkout.currentBranch else { return }
        if branch == loadedBranch, let date = loadedAt[branch], date.timeIntervalSinceNow > -90 { return }
        await refresh()
    }

    func refresh() async {
        let settings = checkout.gitSettings
        guard let branch = checkout.currentBranch,
              let url = checkout.webURL,
              let repository = CodeHostPolicy.codeHost(webURL: url, kind: settings.hostKind, name: settings.hostName)
        else { return }
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer {
                if Task.isCancelled == false {
                    isLoading = false
                }
            }
            if loadedBranch != branch {
                status = nil
            }
            do {
                let loaded = try await self.repository.status(branch: branch, repository: repository)
                try Task.checkCancellation()
                status = loaded
                error = nil
            } catch let failure as PullRequestError {
                try Task.checkCancellation()
                error = failure
            } catch {
                try Task.checkCancellation()
                self.error = .command(error.localizedDescription)
            }
            loadedBranch = branch
            loadedAt[branch] = .now
        }
    }
}
