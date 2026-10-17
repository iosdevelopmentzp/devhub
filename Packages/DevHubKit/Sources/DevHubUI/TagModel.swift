import Foundation

package struct TagModel: Hashable {
    package var text: String
    package var tint: Tint
    package var systemImage: String?
    package var hint: String?

    package init(_ text: String, tint: Tint = .secondary, systemImage: String? = nil, hint: String? = nil) {
        self.text = text
        self.tint = tint
        self.systemImage = systemImage
        self.hint = hint
    }

    package static func icon(_ systemImage: String, tint: Tint, hint: String?) -> TagModel {
        TagModel("", tint: tint, systemImage: systemImage, hint: hint)
    }
}
