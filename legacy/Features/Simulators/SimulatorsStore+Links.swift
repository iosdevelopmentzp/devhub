import Foundation

extension SimulatorsStore {
    func openLink(_ url: String, on simulator: SimulatorInfo) async -> Bool {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return false }
        do {
            try await ensureBooted(simulator.id)
            try await provider.openURL(simulatorID: simulator.id, url: trimmed)
            rememberLink(trimmed)
            activity.log("Open link", detail: "\(trimmed) on \(simulator.name)", outcome: .success)
            return true
        } catch {
            fail("Open link", error.localizedDescription)
            return false
        }
    }

    func sendPush(_ payload: String, bundleID: String, to simulator: SimulatorInfo) async -> Bool {
        if let problem = PushPayload.problem(in: payload) {
            fail("Send push", problem)
            return false
        }
        do {
            try await ensureBooted(simulator.id)
            try await provider.push(simulatorID: simulator.id, bundleID: bundleID, payload: payload)
            activity.log("Send push", detail: "\(bundleID) on \(simulator.name)", outcome: .success)
            toaster.show("Push sent to \(simulator.name)", tint: .green)
            return true
        } catch {
            fail("Send push", error.localizedDescription)
            return false
        }
    }
}
