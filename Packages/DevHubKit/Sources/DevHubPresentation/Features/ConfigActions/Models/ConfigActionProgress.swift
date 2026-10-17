import Foundation
import DevHubDomain
import DevHubUI

struct ConfigActionProgress: Hashable {
    let actionID: String
    let actionTitle: String
    let text: String
    let fraction: Double?
}
