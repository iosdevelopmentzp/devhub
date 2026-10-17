import Foundation
import Observation

@MainActor
@Observable
final class SimulatorsStore {
    private(set) var simulators: [SimulatorInfo] = []
    private(set) var error: String?
    private(set) var isLoading = false
    private(set) var targetID: String?
    private(set) var statuses: [String: SimulatorStatus] = [:]
    private(set) var busy: [String: String] = [:]
    private(set) var confirmation: SimulatorConfirmation?
    private(set) var removal: RemovalProgress?
    private(set) var recentLinks: [String]

    @ObservationIgnored let provider: SimulatorProviding
    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored let config: ConfigStore
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored let toaster: Toaster
    @ObservationIgnored let preferences: AppPreferences
    @ObservationIgnored let projectActions: ProjectActions
    @ObservationIgnored var favoriteIDs: Set<String>
    @ObservationIgnored var removalTask: Task<Void, Never>?
    @ObservationIgnored var statusTasks: [String: Task<Void, Never>] = [:]

    init(
        provider: SimulatorProviding,
        session: ProjectSession,
        config: ConfigStore,
        events: AppEvents,
        activity: ActivityLog,
        toaster: Toaster,
        preferences: AppPreferences,
        projectActions: ProjectActions
    ) {
        self.provider = provider
        self.session = session
        self.config = config
        self.activity = activity
        self.toaster = toaster
        self.preferences = preferences
        self.projectActions = projectActions
        favoriteIDs = Set(preferences.value([String].self, for: .simulatorFavorites) ?? [])
        targetID = preferences.string(.simulatorTarget)
        recentLinks = preferences.value([String].self, for: .recentLinks) ?? []
        events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .simulatorsChanged:
                Task { await self.refresh() }
            case .configChanged, .projectChanged:
                refreshStatuses()
            case .branchesChanged, .worktreesChanged, .commandFailed:
                break
            }
        }
    }

    var sections: [SimulatorSection] { SimulatorSection.build(from: simulators) }

    var target: SimulatorInfo? { simulators.first { $0.id == targetID } }

    var withAppsCount: Int { simulators.filter { $0.appCount > 0 }.count }

    var countText: String {
        "\(simulators.count) simulators"
    }

    var bootedCount: Int { simulators.filter(\.isBooted).count }

    func simulator(id: String) -> SimulatorInfo? {
        simulators.first { $0.id == id }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let listed = try await provider.list()
            simulators = listed.map { simulator in
                var copy = simulator
                copy.isFavorite = favoriteIDs.contains(simulator.id)
                return copy
            }
            error = nil
            chooseTarget()
            refreshStatuses()
        } catch {
            self.error = error.localizedDescription
            activity.log("Simulator list failed", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func executableName(simulatorID: String, bundleID: String) async throws -> String {
        try await provider.executableName(simulatorID: simulatorID, bundleID: bundleID)
    }

    func setTarget(_ id: String) {
        guard simulator(id: id) != nil else { return }
        targetID = id
        preferences.set(id, for: .simulatorTarget)
        mirrorTarget()
    }

    func toggleFavorite(_ id: String) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        preferences.setValue(Array(favoriteIDs).sorted(), for: .simulatorFavorites)
        if let index = simulators.firstIndex(where: { $0.id == id }) {
            simulators[index].isFavorite = favoriteIDs.contains(id)
        }
        refreshStatuses()
    }

    func setConfirmation(_ value: SimulatorConfirmation?) {
        confirmation = value
    }

    func markBusy(_ id: String, _ title: String?) {
        busy[id] = title
    }

    func fail(_ title: String, _ message: String) {
        let summary = message.split(whereSeparator: \.isNewline).first.map(String.init) ?? message
        activity.log(title, detail: message, outcome: .failure)
        toaster.show("\(title) failed: \(summary)", tint: .red)
    }

    func clearStatuses() {
        statuses = [:]
    }

    var removalProgressIsIdle: Bool { removal == nil }

    func setRemoval(_ value: RemovalProgress?) {
        removal = value
    }

    func rememberLink(_ link: String) {
        recentLinks.removeAll { $0 == link }
        recentLinks.insert(link, at: 0)
        recentLinks = Array(recentLinks.prefix(8))
        preferences.setValue(recentLinks, for: .recentLinks)
    }

    func forgetLink(_ link: String) {
        recentLinks.removeAll { $0 == link }
        preferences.setValue(recentLinks, for: .recentLinks)
    }

    func setStatus(_ status: SimulatorStatus?, for id: String) {
        statuses[id] = status
    }

    private func chooseTarget() {
        if let targetID, simulator(id: targetID) != nil {
            mirrorTarget()
            return
        }
        let fallback = simulators.first { $0.isBooted } ?? simulators.first
        targetID = fallback?.id
        preferences.set(fallback?.id, for: .simulatorTarget)
        mirrorTarget()
    }

    private func mirrorTarget() {
        session.setTarget(target.map { TargetSimulator(id: $0.id, name: $0.name, isBooted: $0.isBooted) })
    }
}
