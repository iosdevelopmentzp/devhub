import Foundation
import Observation

nonisolated struct UsageEntry: Sendable {
    var usage: ProviderUsage?
    var error: String?
    var isLoading = false
    var updatedAt: Date?

    var hasContent: Bool { usage != nil || error != nil }
}

@MainActor
@Observable
final class UsageStore {
    private(set) var entries: [UsageProviderID: UsageEntry] = [:]
    var isExpanded = false

    @ObservationIgnored private let provider: UsageProviding
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let layout: WindowLayout
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    init(provider: UsageProviding, settings: SettingsStore, layout: WindowLayout, activity: ActivityLog) {
        self.provider = provider
        self.settings = settings
        self.layout = layout
        self.activity = activity
    }

    var visibleProviders: [UsageProviderID] {
        UsageProviderID.allCases.filter { entries[$0]?.hasContent == true }
    }

    var menuBarText: String {
        var parts: [String] = []
        if settings.showClaudeUsageInMenuBar, let percent = percent(.claude, meter: "five_hour") {
            parts.append("\(percent)%")
        }
        if settings.showCopilotUsageInMenuBar, let percent = percent(.copilot, meter: "premium") {
            parts.append("\(percent)%")
        }
        return parts.joined(separator: " ")
    }

    func entry(_ id: UsageProviderID) -> UsageEntry {
        entries[id] ?? UsageEntry()
    }

    func refreshIfStale(after seconds: TimeInterval = 60) async {
        let now = Date()
        let stale = UsageProviderID.allCases.filter { id in
            guard let updated = entries[id]?.updatedAt else { return true }
            return now.timeIntervalSince(updated) >= seconds
        }
        guard stale.isEmpty == false else { return }
        await withTaskGroup(of: Void.self) { group in
            for id in stale {
                group.addTask { await self.refresh(id) }
            }
        }
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for id in UsageProviderID.allCases {
                group.addTask { await self.refresh(id) }
            }
        }
    }

    func refresh(_ id: UsageProviderID) async {
        guard entries[id]?.isLoading != true else { return }
        entries[id, default: UsageEntry()].isLoading = true
        let provider = provider
        let request = Task { try await provider.usage(for: id) }
        switch await request.result {
        case .success(let usage):
            entries[id] = UsageEntry(usage: usage, error: nil, isLoading: false, updatedAt: Date())
        case .failure(let error):
            fail(id, error)
        }
    }

    private func fail(_ id: UsageProviderID, _ error: Error) {
        let message = error.localizedDescription
        var failed = entries[id] ?? UsageEntry()
        failed.usage = nil
        failed.error = message
        failed.isLoading = false
        failed.updatedAt = Date()
        entries[id] = failed
        activity.log("\(id.title) usage failed", detail: message, outcome: .failure)
    }

    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(30))
                guard let self else { return }
                guard shouldPoll else { continue }
                await refreshIfStale(after: 300)
            }
        }
    }

    private var shouldPoll: Bool {
        layout.isShown || settings.showClaudeUsageInMenuBar || settings.showCopilotUsageInMenuBar
    }

    private func percent(_ id: UsageProviderID, meter: String) -> Int? {
        guard let value = entries[id]?.usage?.meters.first(where: { $0.id == meter }) else { return nil }
        return Int(value.clampedPercent.rounded())
    }
}
