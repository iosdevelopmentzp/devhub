import Foundation
import DevHubDomain

@MainActor
protocol CIAutoRerunLookup: AnyObject {
    func plan(for iid: Int) -> CIAutoRerunPlan?
}
