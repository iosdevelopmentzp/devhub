import Foundation
import DevHubDomain
import DevHubUI

@MainActor
protocol CheckoutContext: AnyObject {
    var checkoutPath: String { get }
    var currentBranch: String? { get }
    var currentUpstream: String? { get }
    var baseName: String { get }
    var baseRef: String { get }
    var gitSettings: GitSettings { get }
    var webURL: URL? { get }
    var localBranchNames: Set<String> { get }
    var isMainCheckoutClean: Bool { get }
    func localBranch(named name: String) -> GitBranch?
    func mergeRequestTargets(for branch: String) -> [String]
}
