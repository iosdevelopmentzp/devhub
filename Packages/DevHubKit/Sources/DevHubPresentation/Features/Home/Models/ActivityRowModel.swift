import Foundation
import DevHubDomain
import DevHubUI

struct ActivityRowModel: Identifiable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var dateText: String
    var dotTint: Tint
    var dotOpacity: Double
    var kindTitle: String?
    var target: ActivityTarget?
    var openHint: String?

    static let preview = ActivityRowModel(
        id: UUID(),
        title: "Built ExampleApp",
        detail: "Debug · example-app",
        dateText: "2 min. ago",
        dotTint: .green,
        dotOpacity: 1,
        kindTitle: "Build",
        target: .build,
        openHint: "Open the run bar"
    )
}
