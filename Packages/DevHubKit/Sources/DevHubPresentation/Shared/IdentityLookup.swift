import Foundation
import DevHubDomain
import DevHubUI

@MainActor
protocol IdentityLookup: AnyObject {
    func buildIdentity(for id: Simulator.ID) -> BuildIdentity?
    func needsCleanInstall(id: Simulator.ID) -> Bool
    func settings(for id: Simulator.ID) -> SimulatorIdentitySettings
    func storedEnvironment(for id: Simulator.ID) -> String?
}
