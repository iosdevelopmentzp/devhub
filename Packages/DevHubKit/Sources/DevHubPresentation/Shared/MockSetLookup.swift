import Foundation
import DevHubDomain
import DevHubUI

@MainActor
protocol MockSetLookup: AnyObject {
    func set(id: MockSet.ID) -> MockSet?
}
