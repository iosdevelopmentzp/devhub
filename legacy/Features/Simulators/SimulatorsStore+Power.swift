import Foundation

extension SimulatorsStore {
    func togglePower(_ simulator: SimulatorInfo) async {
        let booting = simulator.isBooted == false
        markBusy(simulator.id, booting ? "Booting…" : "Shutting down…")
        defer { markBusy(simulator.id, nil) }
        do {
            if booting {
                try await provider.boot(simulator.id)
            } else {
                try await provider.shutdown(simulator.id)
            }
            activity.log(booting ? "Boot" : "Shut down", detail: simulator.name, outcome: .success)
        } catch {
            fail(booting ? "Boot" : "Shut down", error.localizedDescription)
        }
        await refresh()
    }

    func ensureBooted(_ id: String) async throws {
        await refresh()
        guard simulator(id: id)?.isBooted != true else { return }
        try await provider.boot(id)
        await refresh()
    }

    func showInSimulatorApp(_ simulator: SimulatorInfo) async {
        do {
            if simulator.isBooted == false {
                try await ensureBooted(simulator.id)
            }
            try await provider.showInSimulatorApp(simulator.id)
            activity.log("Open in Simulator", detail: simulator.name, outcome: .success)
        } catch {
            fail("Open in Simulator", error.localizedDescription)
        }
    }

    func erase(_ simulator: SimulatorInfo) async {
        setConfirmation(nil)
        markBusy(simulator.id, "Erasing…")
        defer { markBusy(simulator.id, nil) }
        do {
            try await provider.erase(simulator.id)
            activity.log("Erase", detail: simulator.name, outcome: .success)
            toaster.show("Erased \(simulator.name)", tint: .green)
        } catch {
            fail("Erase", error.localizedDescription)
        }
        await refresh()
    }

    func uninstall(bundleID: String, from simulator: SimulatorInfo) async {
        markBusy(simulator.id, "Uninstalling…")
        defer { markBusy(simulator.id, nil) }
        do {
            guard simulator.isBooted else {
                throw SimulatorError(message: "Boot \(simulator.name) first. An app can only be uninstalled on a booted simulator.")
            }
            try await provider.uninstall(simulatorID: simulator.id, bundleID: bundleID)
            activity.log("Uninstall", detail: "\(bundleID) from \(simulator.name)", outcome: .success)
            toaster.show("Uninstalled \(bundleID)", tint: .green)
        } catch {
            fail("Uninstall", error.localizedDescription)
        }
        await refresh()
    }

    func openDataContainer(bundleID: String, of simulator: SimulatorInfo) async {
        do {
            guard simulator.isBooted else {
                throw SimulatorError(message: "Boot \(simulator.name) first. The data container is found through the running simulator.")
            }
            let path = try await provider.dataContainer(simulatorID: simulator.id, bundleID: bundleID)
            projectActions.reveal(path, title: "Open data container")
        } catch {
            fail("Open data container", error.localizedDescription)
        }
    }
}
