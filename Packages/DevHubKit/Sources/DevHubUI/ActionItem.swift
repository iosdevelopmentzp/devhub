import SwiftUI

package struct ActionItem: Identifiable {
    package let id: String
    package let title: String
    package let systemImage: String
    package let hint: String
    package let priority: Int
    package let isDisabled: Bool
    package let tint: Color?
    package let action: () -> Void

    package init(
        _ title: String,
        systemImage: String,
        hint: String,
        priority: Int,
        isDisabled: Bool,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.id = title
        self.title = title
        self.systemImage = systemImage
        self.hint = hint
        self.priority = priority
        self.isDisabled = isDisabled
        self.tint = tint
        self.action = action
    }
}
