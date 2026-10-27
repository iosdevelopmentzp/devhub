import Foundation
import DevHubDomain

enum ProjectSwitchMapper {
    static let shortcutCount = 9

    static func items(projects: [Project], selectedID: Project.ID) -> [ProjectSwitchItem] {
        projects.enumerated().map { index, project in
            ProjectSwitchItem(
                id: project.id,
                title: project.name,
                isSelected: project.id == selectedID,
                digit: index < shortcutCount ? Character(String(index + 1)) : nil
            )
        }
    }
}
