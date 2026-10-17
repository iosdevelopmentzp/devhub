import Foundation
import DevHubDomain
import DevHubUI

struct ConfigActionItemModel: Identifiable, Equatable {
    let id: String
    var title: String
    var systemImage: String
    var hint: String
    var tint: Tint?
    var isEnabled: Bool
    var isRunning: Bool

    static let preview = ConfigActionItemModel(
        id: "clean",
        title: "Clean DerivedData",
        systemImage: "trash",
        hint: "Removes the DerivedData folder of this project",
        tint: .red,
        isEnabled: true,
        isRunning: false
    )
}
