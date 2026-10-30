import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class UsageStore {
    var usage: ClaudeUsage?
    private(set) var error: String?
    var copilot: CopilotUsage?
    private(set) var copilotError: String?
    private(set) var isRefreshing = false
    var providers = UsageProviders.all {
        didSet {
            guard providers != oldValue else { return }
            Task { await refresh() }
        }
    }

    @ObservationIgnored private let repository: ClaudeUsageRepository
    @ObservationIgnored private let copilotRepository: CopilotUsageRepository
    @ObservationIgnored private var pollingTask: Task<Void, Never>?

    init(repository: ClaudeUsageRepository, copilotRepository: CopilotUsageRepository) {
        self.repository = repository
        self.copilotRepository = copilotRepository
    }

    var menuBarPercentText: String? {
        let limits = providers.includesClaude ? usage?.limits : copilot?.limits
        return limits?.first?.percentText
    }

    func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while Task.isCancelled == false {
                guard let self else { return }
                await refresh()
                try? await Task.sleep(for: .seconds(300))
            }
        }
    }

    func refreshIfStale() async {
        let updatedAt = providers.includesClaude ? usage?.updatedAt : copilot?.updatedAt
        if let updatedAt, updatedAt.timeIntervalSinceNow > -60 { return }
        await refresh()
    }

    func refresh() async {
        guard isRefreshing == false else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        async let claude: Void = refreshClaude()
        async let copilot: Void = refreshCopilot()
        _ = await (claude, copilot)
    }

    private func refreshClaude() async {
        guard providers.includesClaude else { return }
        do {
            usage = try await repository.fetch()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func refreshCopilot() async {
        guard providers.includesCopilot else { return }
        do {
            copilot = try await copilotRepository.fetch()
            copilotError = nil
        } catch {
            copilotError = error.localizedDescription
        }
    }
}
