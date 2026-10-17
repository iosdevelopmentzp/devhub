import Foundation
import DevHubDomain
import DevHubUI

struct PendingConfigAction: Hashable {
    let action: ResolvedAction
    let slot: String
    var item: ActionItemContext
    var inputs: [String: String]
}
