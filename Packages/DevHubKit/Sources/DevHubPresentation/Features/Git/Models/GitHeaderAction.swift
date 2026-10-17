import Foundation
import DevHubDomain
import DevHubUI

enum GitHeaderAction: Hashable {
    case fetch
    case pull
    case push
    case forcePush
    case rebase
    case updateBase
    case stash
    case popStash
}
