import Foundation
import DevHubDomain
import DevHubUI

@MainActor
protocol IdentityLookup: AnyObject {
    var identityConfig: LaunchIdentityConfig? { get }
    func bundleID(for id: Simulator.ID) -> String
    func settings(for id: Simulator.ID) -> SimulatorLaunchSettings
    func needsCleanInstall(id: Simulator.ID) -> Bool
    func installedApp(for id: Simulator.ID) -> InstalledApp?
    func actualIdentity(for id: Simulator.ID) -> String?
    func report(for id: Simulator.ID) -> AppStateReport?
}
