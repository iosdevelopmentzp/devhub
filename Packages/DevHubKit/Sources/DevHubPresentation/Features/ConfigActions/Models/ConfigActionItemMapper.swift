import Foundation
import DevHubDomain
import DevHubUI

enum ConfigActionItemMapper {
    static let defaultSymbol = "terminal"

    static func model(for action: ResolvedAction, isRunning: Bool) -> ConfigActionItemModel {
        ConfigActionItemModel(
            id: action.id,
            title: action.config.title,
            systemImage: action.config.icon ?? defaultSymbol,
            tint: ConfigTintMapper.tint(action.config.tint),
            isEnabled: action.origin.isExecutable && isRunning == false,
            isRunning: isRunning
        )
    }
}
