import Foundation
import DevHubDomain
import DevHubUI

struct ProjectSettingsRowModel: Identifiable, Equatable {
    let id: Project.ID
    var name: String
    var path: String
    var icon: String
    var iconTint: Tint
    var iconHint: String
    var deviceToolsTag: TagModel?
    var canRemove: Bool
    var removeHint: String
    var removeQuestion: String

    static let preview = ProjectSettingsRowModel(
        id: "example-app",
        name: "ExampleApp",
        path: "/Users/dev/Projects/ExampleApp",
        icon: "shippingbox.fill",
        iconTint: .indigo,
        iconHint: "The project DevHub shows now",
        deviceToolsTag: TagModel(
            "device tools",
            tint: .indigo,
            systemImage: "person.text.rectangle",
            hint: "Device ID and environment per simulator are available for this app"
        ),
        canRemove: true,
        removeHint: "Remove from DevHub. Files stay on disk.",
        removeQuestion: "Remove ExampleApp from DevHub? The folder stays on disk."
    )
}
