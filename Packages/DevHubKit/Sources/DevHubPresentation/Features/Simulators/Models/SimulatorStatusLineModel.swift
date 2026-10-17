import Foundation
import DevHubDomain
import DevHubUI

struct SimulatorStatusLineModel: Equatable {
    var text: String
    var tint: Tint

    static let preview = SimulatorStatusLineModel(text: "Environment: staging · User: qa-12", tint: .secondary)
}
