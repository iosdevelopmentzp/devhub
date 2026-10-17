import Foundation
import DevHubDomain
import DevHubUI

struct UsageMeterModel: Identifiable, Equatable {
    let id: UsageLimit.ID
    var title: String
    var percentText: String
    var fraction: Double
    var levelTint: Tint?
    var resetText: String

    static let preview = UsageMeterModel(
        id: "five_hour",
        title: "Session",
        percentText: "64%",
        fraction: 0.64,
        levelTint: .orange,
        resetText: "Resets in 2h 15m"
    )
}
