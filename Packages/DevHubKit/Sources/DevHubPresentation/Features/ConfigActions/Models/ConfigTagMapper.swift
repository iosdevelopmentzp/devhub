import Foundation
import DevHubDomain
import DevHubUI

enum ConfigTagMapper {
    static func model(_ tag: ScriptViewTag) -> TagModel {
        TagModel(tag.text, tint: ConfigTintMapper.tint(tag.tint), systemImage: tag.icon, hint: tag.hint)
    }
}
