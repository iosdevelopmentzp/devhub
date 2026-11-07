import Foundation
import DevHubDomain
import DevHubUI

struct TrackerToolModel: Equatable {
    var icon: String
    var tint: Tint
    var title: String
    var detail: String
    var command: String?
    var showsCheckAgain: Bool
    var isWorking: Bool
    var isCompact: Bool

    static let preview = TrackerToolMapper.model(for: .notLoggedIn, isChecking: false)
}
