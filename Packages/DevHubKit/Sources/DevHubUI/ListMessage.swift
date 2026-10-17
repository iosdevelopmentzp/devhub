import Foundation

package struct ListMessage {
    package let title: String
    package let systemImage: String
    package let description: String
    package let actionTitle: String?
    package let action: (() -> Void)?

    package init(_ title: String, systemImage: String, description: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    package static func failure(_ title: String, description: String, actionTitle: String? = "Retry", action: (() -> Void)? = nil) -> ListMessage {
        ListMessage(title, systemImage: "exclamationmark.triangle", description: description, actionTitle: actionTitle, action: action)
    }
}
