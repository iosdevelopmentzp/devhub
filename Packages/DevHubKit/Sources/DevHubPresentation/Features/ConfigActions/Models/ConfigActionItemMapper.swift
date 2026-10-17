import Foundation
import DevHubDomain
import DevHubUI

enum ConfigActionItemMapper {
    static let defaultSymbol = "terminal"

    static func models(for actions: [CatalogAction], isRunning: (String) -> Bool) -> [ConfigActionItemModel] {
        actions.compactMap(\.resolved).map { model(for: $0, isRunning: isRunning($0.id)) }
    }

    static func model(for action: ResolvedAction, isRunning: Bool) -> ConfigActionItemModel {
        ConfigActionItemModel(
            id: action.id,
            title: action.config.title,
            systemImage: action.config.icon ?? defaultSymbol,
            hint: hint(for: action, isRunning: isRunning),
            tint: action.config.tint.map(ConfigTintMapper.tint),
            isEnabled: action.origin.isExecutable && isRunning == false,
            isRunning: isRunning
        )
    }

    private static func hint(for action: ResolvedAction, isRunning: Bool) -> String {
        guard action.origin.isExecutable else { return "Run chmod +x on \(action.origin.fileName) first" }
        guard isRunning == false else { return "\(action.config.title) is running" }
        return action.config.subtitle ?? action.config.title
    }
}
