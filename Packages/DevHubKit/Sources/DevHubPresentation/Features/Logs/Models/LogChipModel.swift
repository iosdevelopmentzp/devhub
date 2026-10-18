import Foundation
import DevHubDomain
import DevHubUI

struct LogChipModel: Identifiable, Equatable {
    let id: Simulator.ID
    var title: String
    var dotTint: Tint
    var isSelected: Bool

    static let preview = LogChipModel(id: "8C2F6A1E-5B3D-4E7A-9F10-2D4C6B8A0E13", title: "iPhone 17 · booted", dotTint: .green, isSelected: true)
}
