import Foundation
import DevHubDomain
import DevHubUI

enum ProjectSettingsRowMapper {

    private static let deviceToolsTag = TagModel(
        "launch identity",
        tint: .indigo,
        systemImage: "person.text.rectangle",
        hint: "launch.identity is set in .devhub/project.json: each simulator can launch the app with its own ID"
    )

    static func model(for project: Project, isSelected: Bool, hasLaunchIdentity: Bool, projectCount: Int) -> ProjectSettingsRowModel {
        let canRemove = projectCount > 1
        return ProjectSettingsRowModel(
            id: project.id,
            name: project.name,
            path: project.path,
            icon: isSelected ? "shippingbox.fill" : "shippingbox",
            iconTint: isSelected ? .indigo : .secondary,
            iconHint: isSelected ? "The project DevHub shows now" : "Another project. Switch in the header.",
            deviceToolsTag: isSelected && hasLaunchIdentity ? deviceToolsTag : nil,
            canRemove: canRemove,
            removeHint: canRemove ? "Remove from DevHub. Files stay on disk." : "The last project cannot be removed",
            removeQuestion: "Remove \(project.name) from DevHub? The folder stays on disk."
        )
    }

    static func project(_ project: Project, setting keyPath: WritableKeyPath<Project, String>, to value: String) -> Project {
        var updated = project
        updated[keyPath: keyPath] = value
        return updated
    }

    static func redetectMessage(for project: Project) -> String {
        let scheme = project.scheme.isEmpty ? "no scheme" : "scheme \(project.scheme)"
        let bundleID = project.bundleID.isEmpty ? "no bundle ID" : "bundle ID \(project.bundleID)"
        return "\(project.name): \(scheme), \(bundleID)"
    }
}
