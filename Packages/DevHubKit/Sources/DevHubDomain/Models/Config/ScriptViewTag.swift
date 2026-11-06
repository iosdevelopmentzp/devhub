import Foundation

package struct ScriptViewTag: Codable, Hashable, Sendable {
    package var text: String
    package var tint: ConfigTint? = nil
    package var icon: String? = nil
    package var hint: String? = nil

    package init(
        text: String,
        tint: ConfigTint? = nil,
        icon: String? = nil,
        hint: String? = nil
    ) {
        self.text = text
        self.tint = tint
        self.icon = icon
        self.hint = hint
    }
}
