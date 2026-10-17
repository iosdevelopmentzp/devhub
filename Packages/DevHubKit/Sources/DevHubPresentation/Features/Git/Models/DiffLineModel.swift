import Foundation
import DevHubDomain
import DevHubUI

struct DiffLineModel: Identifiable, Equatable {
    let id: Int
    var text: String
    var tint: Tint?
    var foregroundOpacity: Double
    var backgroundOpacity: Double
    var oldNumber: Int?
    var newNumber: Int?

    static let preview = DiffLineModel(id: 0, text: "+    let value: GiftValue", tint: .green, foregroundOpacity: 0.9, backgroundOpacity: 0.08, oldNumber: nil, newNumber: 42)
}
