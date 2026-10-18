#if DEBUG
import Foundation
import DevHubDomain

package extension PresentationAssembly {
    func debugApplyMocks(_ spec: String) async {
        let parts = spec.split(separator: ",", omittingEmptySubsequences: false).map { String($0).trimmed }
        await simulators.refresh()
        await config.reload()
        await mockSets.load()
        guard let target = parts.first, let simulator = simulators.all.first(where: { $0.id == target || $0.name == target }) else {
            activity.log("Debug mocks", detail: "No simulator \(parts.first ?? "").", outcome: .failure)
            return
        }
        guard parts.count > 1, let mode = MockMode(rawValue: parts[1]) else {
            activity.log("Debug mocks", detail: "Mode must be off, passthrough or mock.", outcome: .failure)
            return
        }
        await identity.refresh(id: simulator.id)
        network.selectedUDID = simulator.id
        mockServer.setMode(mode, for: simulator.id)
        if parts.count > 2 {
            mockServer.selectSet(mockSets.sets.first { $0.name == parts[2] }?.id, for: simulator.id)
        }
        mockServer.apply(on: simulator.id)
        for _ in 0..<300 {
            try? await Task.sleep(for: .milliseconds(100))
            guard mockServer.isApplying(simulator.id) else { break }
        }
        activity.log("Debug mocks", detail: mockServer.errors[simulator.id] ?? "Applied \(mode.rawValue)", outcome: .info)
    }
}
#endif
