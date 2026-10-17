import Foundation
import DevHubDomain
import DevHubUI

struct SimulatorSectionModel: Identifiable, Equatable {
    let id: String
    var title: String
    var systemImage: String?
    var detail: String
    var rows: [SimulatorRowModel]

    static let preview = SimulatorSectionModel(
        id: "favorites",
        title: "Favorites",
        systemImage: "star.fill",
        detail: "1 devices",
        rows: [.preview]
    )
}
