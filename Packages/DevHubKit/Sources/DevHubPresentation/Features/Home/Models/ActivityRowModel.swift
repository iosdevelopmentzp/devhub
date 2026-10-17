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

    static let preview = ActivityRowModel(
        id: UUID(),
        title: "Build succeeded",
        detail: "ExampleApp · iPhone 17 Pro",
        dateText: "2 min. ago",
        dotTint: .green,
        dotOpacity: 1
    )
}
