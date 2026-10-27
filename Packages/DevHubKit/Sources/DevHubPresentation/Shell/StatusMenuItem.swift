import Foundation
import DevHubDomain

enum StatusMenuItem: Equatable {
    case show
    case projectsHeader
    case project(id: Project.ID, title: String, isSelected: Bool)
    case keepAwake(isOn: Bool)
    case settings
    case quit
    case separator
}
