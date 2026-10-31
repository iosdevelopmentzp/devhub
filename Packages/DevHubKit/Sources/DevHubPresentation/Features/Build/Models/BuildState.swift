import Foundation
import DevHubDomain
import DevHubUI

struct BuildState: Hashable {
    enum Phase: Hashable {
        case idle
        case running(step: String, progress: Double?)
        case succeeded(Date, launched: Bool)
        case failed(String)
    }

    var phase: Phase = .idle
    var scheme = "ExampleApp"
    var configuration = "Debug"
    var incremental = true
    var cleanInstall = false
    var profileID: String?
    var targetSimulatorID: Simulator.ID?

    var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }
}
