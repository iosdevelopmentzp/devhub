import Foundation
import DevHubDomain
import DevHubUI

struct UsageSummaryModel: Equatable {
    var meters: [UsageMeterModel]
    var planTag: TagModel
    var updatedText: String
    var note: String?

    static let preview = UsageSummaryModel(
        meters: [
            .preview,
            UsageMeterModel(
                id: "seven_day",
                title: "Week",
                percentText: "22%",
                fraction: 0.22,
                levelTint: nil,
                resetText: "Resets Thu 09:00"
            )
        ],
        planTag: TagModel("Max", tint: .indigo, systemImage: "person.2"),
        updatedText: "Updated 1 min. ago",
        note: nil
    )
}
