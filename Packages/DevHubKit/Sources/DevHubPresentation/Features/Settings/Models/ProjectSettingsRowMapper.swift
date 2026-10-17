import Foundation
import DevHubDomain
import DevHubUI

enum ProjectSettingsRowMapper {

    private static let deviceToolsTag = TagModel(
        "device tools",
        tint: .indigo,
        systemImage: "person.text.rectangle",
        hint: "Device ID and environment per simulator are available for this app"
    )

    static func model(for project: Project, isSelected: Bool, projectCount: Int) -> ProjectSettingsRowModel {
        let canRemove = projectCount > 1
        return ProjectSettingsRowModel(
            id: project.id,
            name: project.name,
            path: project.path,
            icon: isSelected ? "shippingbox.fill" : "shippingbox",
            iconTint: isSelected ? .indigo : .secondary,
            iconHint: isSelected ? "The project DevHub shows now" : "Another project. Switch in the header.",
            deviceToolsTag: project.identity == nil ? nil : deviceToolsTag,
            canRemove: canRemove,
            removeHint: canRemove ? "Remove from DevHub. Files stay on disk." : "The last project cannot be removed",
            removeQuestion: "Remove \(project.name) from DevHub? The folder stays on disk."
        )
    }

    static func project(_ project: Project, setting keyPath: WritableKeyPath<Project, String>, to value: String) -> Project {
        var updated = project
        updated[keyPath: keyPath] = value
        if updated.bundleID != project.bundleID {
            updated.identity = nil
        }
        return updated
    }
}
