import Foundation
import DevHubUI

struct KeepAwakeCardModel: Equatable {
    var isActive: Bool
    var title: String
    var subtitle: String
    var systemImage: String
    var tint: Tint

    static let preview = KeepAwakeCardMapper.model(isActive: true)
}
