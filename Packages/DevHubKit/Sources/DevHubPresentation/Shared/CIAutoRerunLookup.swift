import Foundation
import DevHubDomain

@MainActor
protocol CIAutoRerunLookup: AnyObject {
    var onlyFlaky: Bool { get }
    func plan(for iid: Int) -> CIAutoRerunPlan?
}
