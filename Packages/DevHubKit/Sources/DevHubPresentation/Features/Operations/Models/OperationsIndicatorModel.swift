import Foundation
import DevHubDomain
import DevHubUI

struct OperationsIndicatorModel: Equatable {
    var text: String?
    var icon: String
    var tint: Tint
    var textTint: Tint
    var isRunning: Bool
    var hint: String

    static let preview = OperationsIndicatorModel(text: "Push feature/ABC-123-short-title", icon: "circle.dotted", tint: .blue, textTint: .secondary, isRunning: true, hint: "Show the operations of this session")
}
