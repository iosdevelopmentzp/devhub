import Foundation
import DevHubDomain
import DevHubUI

struct VideoEngineModel: Equatable {
    enum Action: Equatable {
        case install(String)
        case getHomebrew
        case checkAgain
    }

    var icon: String
    var tint: Tint
    var title: String
    var detail: String
    var action: Action?
    var command: String?
    var isWorking: Bool
    var isCompact: Bool

    static let preview = VideoEngineMapper.model(for: .missing(homebrewPath: "/opt/homebrew/bin/brew"), install: .idle, isChecking: false)
}
