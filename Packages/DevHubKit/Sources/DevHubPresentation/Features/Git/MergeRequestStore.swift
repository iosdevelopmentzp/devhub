import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class MergeRequestStore {
    private(set) var status: MergeRequestStatus?
    private(set) var error: MergeRequestError?
    private(set) var isLoading = false
    private(set) var loadedBranch: String?

    @ObservationIgnored private let repository: MergeRequestRepository
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private var loadedAt: [String: Date] = [:]
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private let refreshTask = RefreshTask()

    init(repository: MergeRequestRepository, checkout: any CheckoutContext, events: AppEvents) {
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
        guard let branch = checkout.currentBranch, let repository = checkout.webURL else { return }
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
            } catch let failure as MergeRequestError {
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
