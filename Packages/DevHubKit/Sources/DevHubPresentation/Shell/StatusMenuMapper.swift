import Foundation
import DevHubDomain

enum StatusMenuMapper {
    static func items(projects: [Project], selectedID: Project.ID, isKeepAwakeOn: Bool) -> [StatusMenuItem] {
        var items: [StatusMenuItem] = [.show, .separator]
        if projects.count > 1 {
            items.append(.projectsHeader)
            items += projects.map { .project(id: $0.id, title: $0.name, isSelected: $0.id == selectedID) }
            items.append(.separator)
        }
        items += [.keepAwake(isOn: isKeepAwakeOn), .separator, .checkForUpdates, .settings, .separator, .quit]
        return items
    }
}
