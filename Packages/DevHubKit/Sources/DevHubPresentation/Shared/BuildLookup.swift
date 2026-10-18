import Foundation
import DevHubDomain
import DevHubUI

@MainActor
protocol BuildLookup: AnyObject {
    var schemeOptions: [String] { get }
    var selectedScheme: String { get }
    var selectedConfiguration: String { get }
    var target: Simulator? { get }
    func lastBuiltAppPath() -> String?
    func profile(for id: Simulator.ID) -> LaunchProfile?
}
