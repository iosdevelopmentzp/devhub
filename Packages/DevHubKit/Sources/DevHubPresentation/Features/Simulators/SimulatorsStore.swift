import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class SimulatorsStore: SimulatorLookup {
    var groups: [SimulatorGroup] = []
    var installedAppCounts: [Simulator.ID: Int] = [:]
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var uninstallingIDs: Set<Simulator.ID> = []
    private(set) var bulkUninstall: BulkProgress?
    private(set) var favoriteOrder: [Simulator.ID]

    @ObservationIgnored private let repository: SimulatorRepository
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let runner: ActionRunner
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var bulkUninstallTask: Task<Void, Never>?
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let favoritesKey = "simulators.favorites"

    init(repository: SimulatorRepository, activity: ActivityLog, operations: OperationLog, events: AppEvents, store: any KeyValueStore) {
        self.repository = repository
        self.activity = activity
        runner = ActionRunner(activity: activity, operations: operations, origin: .simulators)
        self.events = events
        self.store = store
        favoriteOrder = store.strings(forKey: Self.favoritesKey) ?? []
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .buildFinished, .appLaunched, .refreshRequested(.simulators):
                Task { await self.refresh() }
            case .projectChanged, .branchesChanged, .worktreesChanged, .simulatorsChanged, .commandFailed, .buildStarted, .worktreeCheckoutPrepared, .worktreeBootstrapping, .mockSetChanged, .pullRequestsChanged, .pullRequestChecksChanged, .pullRequestReviewed, .configChanged, .appStateReported, .refreshRequested:
                break
            }
        }
    }

    var all: [Simulator] {
        groups.flatMap(\.simulators)
    }

    var withApps: [Simulator] {
        all.filter { (installedAppCounts[$0.id] ?? 0) > 0 }
    }

    func simulator(id: Simulator.ID) -> Simulator? {
        all.first { $0.id == id }
    }

    func runtime(for id: Simulator.ID) -> String? {
        groups.first { group in group.simulators.contains { $0.id == id } }?.runtime
    }

    func isUninstalling(_ id: Simulator.ID) -> Bool {
        uninstallingIDs.contains(id)
    }

    // MARK: Reading

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer {
                if Task.isCancelled == false {
                    isLoading = false
                }
            }
            do {
                var loaded = try await repository.list()
                try Task.checkCancellation()
                for groupIndex in loaded.indices {
                    for index in loaded[groupIndex].simulators.indices {
                        loaded[groupIndex].simulators[index].isFavorite = favoriteOrder.contains(loaded[groupIndex].simulators[index].id)
                    }
                }
                groups = loaded
                error = nil
                let counts = await repository.installedAppCounts(udids: all.map(\.id))
                try Task.checkCancellation()
                installedAppCounts = counts
                events.post(.simulatorsChanged)
            } catch {
                try Task.checkCancellation()
                self.error = error.localizedDescription
                activity.log("Simulator list failed", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    // MARK: Power

    func togglePower(id: Simulator.ID) {
        guard let simulator = simulator(id: id) else { return }
        switch simulator.state {
        case .booted:
            update(id: id) { $0.state = .shuttingDown }
            perform("Shut down", simulator) { [repository] in
                try await repository.shutdown(udid: id)
            }
        case .shutdown:
            update(id: id) { $0.state = .booting }
            perform("Booted", simulator) { [repository] in
                try await repository.boot(udid: id)
            }
        case .booting, .shuttingDown:
            break
        }
    }

    func erase(id: Simulator.ID) {
        guard let simulator = simulator(id: id) else { return }
        update(id: id) { $0.state = .shuttingDown }
        perform("Erased", simulator) { [repository] in
            try await repository.erase(udid: id)
        }
    }

    func openInSimulatorApp(id: Simulator.ID) {
        guard let simulator = simulator(id: id) else { return }
        perform("Opened in Simulator.app", simulator) { [repository] in
            try await repository.openInSimulatorApp(udid: id)
        }
    }

    func toggleFavorite(id: Simulator.ID) {
        if let index = favoriteOrder.firstIndex(of: id) {
            favoriteOrder.remove(at: index)
        } else {
            favoriteOrder.append(id)
        }
        store.set(favoriteOrder, forKey: Self.favoritesKey)
        update(id: id) { $0.isFavorite.toggle() }
    }

    func moveFavorite(id: Simulator.ID, onto target: Simulator.ID) {
        let moved = FavoriteOrder.moved(favoriteOrder, id: id, onto: target)
        guard moved != favoriteOrder else { return }
        favoriteOrder = moved
        store.set(favoriteOrder, forKey: Self.favoritesKey)
    }

    // MARK: Apps

    func uninstallUserApps(id: Simulator.ID) {
        guard let simulator = simulator(id: id) else { return }
        let wasBooted = simulator.state == .booted
        uninstallingIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            do {
                let removed = try await repository.uninstallUserApps(udid: id, wasBooted: wasBooted)
                let detail = removed.isEmpty ? "No installed apps" : removed.joined(separator: ", ")
                activity.log("Removed apps from \(simulator.name)", detail: detail, outcome: .success)
            } catch {
                activity.log("Removing apps failed: \(simulator.name)", detail: error.localizedDescription, outcome: .failure)
            }
            uninstallingIDs.remove(id)
            await refresh()
        }
    }

    func uninstall(bundleID: String, from id: Simulator.ID) {
        guard let simulator = simulator(id: id) else { return }
        let wasBooted = simulator.state == .booted
        uninstallingIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.uninstall(udid: id, bundleID: bundleID, wasBooted: wasBooted)
                activity.log("Uninstalled \(bundleID)", detail: simulator.name, outcome: .success)
            } catch {
                activity.log("Uninstall failed: \(simulator.name)", detail: error.localizedDescription, outcome: .failure)
            }
            uninstallingIDs.remove(id)
            await refresh()
        }
    }

    func removeAppsFromAll() {
        let targets = withApps
        guard targets.isEmpty == false, bulkUninstall == nil else { return }
        bulkUninstall = BulkProgress(done: 0, total: targets.count, current: targets[0].name)
        bulkUninstallTask = Task { [weak self] in
            guard let self else { return }
            var removedApps = 0
            var failures: [String] = []
            for (index, simulator) in targets.enumerated() {
                guard Task.isCancelled == false else { break }
                bulkUninstall = BulkProgress(done: index, total: targets.count, current: simulator.name)
                uninstallingIDs.insert(simulator.id)
                do {
                    let removed = try await repository.uninstallUserApps(udid: simulator.id, wasBooted: simulator.state == .booted)
                    removedApps += removed.count
                    installedAppCounts[simulator.id] = 0
                } catch {
                    failures.append(simulator.name)
                }
                uninstallingIDs.remove(simulator.id)
            }
            let wasCancelled = Task.isCancelled
            bulkUninstall = nil
            bulkUninstallTask = nil
            let detail = "\(removedApps) apps" + (failures.isEmpty ? "" : " · failed on \(failures.joined(separator: ", "))")
            activity.log(wasCancelled ? "Stopped removing apps" : "Removed apps from all simulators", detail: detail, outcome: failures.isEmpty ? .success : .failure)
            await refresh()
        }
    }

    func cancelBulkUninstall() {
        bulkUninstallTask?.cancel()
    }

    // MARK: Private

    private func perform(_ title: String, _ simulator: Simulator, _ work: @escaping () async throws -> Void) {
        runner.run(
            "\(title) \(simulator.name)",
            detail: runtime(for: simulator.id) ?? "",
            failureTitle: "\(title) failed: \(simulator.name)",
            completion: { [weak self] in
                guard let self else { return }
                await refresh()
            },
            work: work
        )
    }

    private func update(id: Simulator.ID, _ mutate: (inout Simulator) -> Void) {
        for groupIndex in groups.indices {
            guard let index = groups[groupIndex].simulators.firstIndex(where: { $0.id == id }) else { continue }
            mutate(&groups[groupIndex].simulators[index])
            return
        }
    }
}
