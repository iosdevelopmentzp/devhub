import Foundation
import DevHubDomain
import DevHubUI

struct ConfigActionOutcome: Hashable {
    var error: String?
    var view: ScriptView?
    var refresh: Set<RefreshTarget> = []
}
