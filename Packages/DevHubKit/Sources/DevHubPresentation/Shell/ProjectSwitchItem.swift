import Foundation
import DevHubDomain

struct ProjectSwitchItem: Identifiable, Equatable {
    let id: Project.ID
    var title: String
    var isSelected: Bool
    var digit: Character?

    var shortcutText: String? {
        digit.map { "⌃⌘\($0)" }
    }
}
