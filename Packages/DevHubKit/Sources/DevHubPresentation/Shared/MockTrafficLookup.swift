import Foundation
import DevHubDomain
import DevHubUI

@MainActor
protocol MockTrafficLookup: AnyObject {
    func isIntercepting(_ id: Simulator.ID) -> Bool
    func exchanges(for id: Simulator.ID) -> [NetworkRequest]
    func clearExchanges(for id: Simulator.ID)
}
