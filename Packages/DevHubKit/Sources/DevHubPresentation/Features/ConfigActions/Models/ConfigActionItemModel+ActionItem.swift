import SwiftUI
import DevHubUI

extension ConfigActionItemModel {
    func actionItem(priority: Int, onRun: @escaping (ID) -> Void) -> ActionItem {
        ActionItem(
            title,
            systemImage: systemImage,
            hint: hint,
            priority: priority,
            isDisabled: isEnabled == false,
            tint: tint?.color
        ) {
            onRun(id)
        }
    }
}
