import Foundation

package struct ScriptViewTag: Codable, Hashable, Sendable {
    package var text: String
    package var tint: ConfigTint? = nil

    package init(
        text: String,
        tint: ConfigTint? = nil
    ) {
        self.text = text
        self.tint = tint
    }
}
