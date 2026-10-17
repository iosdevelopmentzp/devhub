import Foundation
import DevHubDomain
import DevHubUI

struct QuickActionTileModel: Identifiable, Equatable {
    let id: String
    var title: String
    var subtitle: String
    var systemImage: String
    var tint: Tint
    var isRunning: Bool
    var isEnabled: Bool

    static let preview = QuickActionTileModel(id: "builtin.buildRun", title: "Build & Run", subtitle: "Scheme ExampleApp", systemImage: "play.fill", tint: .green, isRunning: false, isEnabled: true)
}
