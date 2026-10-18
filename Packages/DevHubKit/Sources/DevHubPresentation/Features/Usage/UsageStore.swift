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

    @ObservationIgnored private let repository: ClaudeUsageRepository
    @ObservationIgnored private let copilotRepository: CopilotUsageRepository
    @ObservationIgnored private var pollingTask: Task<Void, Never>?

    init(repository: ClaudeUsageRepository, copilotRepository: CopilotUsageRepository) {
        self.repository = repository
        self.copilotRepository = copilotRepository
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
        if let usage, usage.updatedAt.timeIntervalSinceNow > -60 { return }
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
        do {
            usage = try await repository.fetch()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func refreshCopilot() async {
        do {
            copilot = try await copilotRepository.fetch()
            copilotError = nil
        } catch {
            copilotError = error.localizedDescription
        }
    }
}
