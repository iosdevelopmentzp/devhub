import Foundation

extension SimulatorsStore {
    func removeApps(from simulator: SimulatorInfo) async {
        markBusy(simulator.id, "Removing apps…")
        defer { markBusy(simulator.id, nil) }
        do {
            let removed = try await removeUserApps(of: simulator)
            activity.log("Remove apps", detail: "\(removed) from \(simulator.name)", outcome: .success)
            toaster.show("Removed \(removed) apps from \(simulator.name)", tint: .green)
        } catch is CancellationError {
            activity.log("Remove apps", detail: "Cancelled", outcome: .info)
        } catch {
            fail("Remove apps", error.localizedDescription)
        }
        await refresh()
    }

    func askRemoveAll() {
        setConfirmation(.removeAll)
    }

    func startRemovingFromAll() {
        setConfirmation(nil)
        let targets = simulators.filter { $0.appCount > 0 }
        guard targets.isEmpty == false, removalProgressIsIdle else { return }
        setRemoval(RemovalProgress(done: 0, total: targets.count, name: targets[0].name))
        removalTask = Task { [weak self] in
            guard let self else { return }
            await removeFromAll(targets)
        }
    }

    func stopRemoving() {
        removalTask?.cancel()
    }

    private func removeFromAll(_ targets: [SimulatorInfo]) async {
        var removedTotal = 0
        var stopped = false
        for (index, simulator) in targets.enumerated() {
            setRemoval(RemovalProgress(done: index, total: targets.count, name: simulator.name))
            do {
                removedTotal += try await removeUserApps(of: simulator)
            } catch is CancellationError {
                stopped = true
                break
            } catch {
                fail("Remove apps", "\(simulator.name): \(error.localizedDescription)")
            }
        }
        setRemoval(nil)
        removalTask = nil
        activity.log("Remove apps from all", detail: "\(removedTotal) apps removed" + (stopped ? " (stopped)" : ""), outcome: stopped ? .info : .success)
        toaster.show(stopped ? "Stopped. Removed \(removedTotal) apps" : "Removed \(removedTotal) apps", tint: stopped ? .orange : .green)
        await refresh()
    }

    private func removeUserApps(of simulator: SimulatorInfo) async throws -> Int {
        let wasBooted = simulator.isBooted
        if wasBooted == false {
            try await provider.boot(simulator.id)
        }
        var removed = 0
        do {
            for app in try await provider.userApps(simulator.id) {
                try Task.checkCancellation()
                try await provider.uninstall(simulatorID: simulator.id, bundleID: app.bundleID)
                removed += 1
            }
        } catch {
            if wasBooted == false {
                try? await provider.shutdown(simulator.id)
            }
            throw error
        }
        if wasBooted == false {
            try await provider.shutdown(simulator.id)
        }
        return removed
    }
}
