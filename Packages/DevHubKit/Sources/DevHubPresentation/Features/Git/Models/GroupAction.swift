import Foundation
import DevHubDomain
import DevHubUI

struct GroupAction: Equatable {
    enum Kind: Equatable {
        case stageAll
        case unstageAll
    }

    let title: String
    let kind: Kind
}
