import Foundation
import DevHubDomain
import DevHubUI

struct LogsToolbarModel: Equatable {
    var pauseTitle: String
    var canCopy: Bool
    var copyLabel: String
    var canClear: Bool
    var lineCountText: String
    var droppedText: String?
}
