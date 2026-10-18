import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation
import DevHubTestSupport

@Suite struct ProjectSettingsRowMapperTests {
    @Test func selectedProjectWithALaunchIdentity() {
        let model = ProjectSettingsRowMapper.model(for: ProjectFixture.exampleApp, isSelected: true, hasLaunchIdentity: true, projectCount: 2)

        #expect(model.id == "example-app")
        #expect(model.name == "ExampleApp")
        #expect(model.path == "/Users/dev/Projects/ExampleApp")
        #expect(model.icon == "shippingbox.fill")
        #expect(model.iconTint == .indigo)
        #expect(model.iconHint == "The project DevHub shows now")
        #expect(model.deviceToolsTag == TagModel(
            "launch identity",
            tint: .indigo,
            systemImage: "person.text.rectangle",
            hint: "launch.identity is set in .devhub/project.json: each simulator can launch the app with its own ID"
        ))
        #expect(model.canRemove)
        #expect(model.removeHint == "Remove from DevHub. Files stay on disk.")
        #expect(model.removeQuestion == "Remove ExampleApp from DevHub? The folder stays on disk.")
    }

    @Test func otherProjectHasNoLaunchIdentityTag() {
        let model = ProjectSettingsRowMapper.model(for: ProjectFixture.devHub, isSelected: false, hasLaunchIdentity: true, projectCount: 2)

        #expect(model.icon == "shippingbox")
        #expect(model.iconTint == .secondary)
        #expect(model.iconHint == "Another project. Switch in the header.")
        #expect(model.deviceToolsTag == nil)
    }

    @Test func selectedProjectWithoutALaunchIdentityHasNoTag() {
        let model = ProjectSettingsRowMapper.model(for: ProjectFixture.exampleApp, isSelected: true, hasLaunchIdentity: false, projectCount: 2)

        #expect(model.deviceToolsTag == nil)
    }

    @Test func lastProjectCannotBeRemoved() {
        let model = ProjectSettingsRowMapper.model(for: ProjectFixture.exampleApp, isSelected: true, hasLaunchIdentity: false, projectCount: 1)

        #expect(model.canRemove == false)
        #expect(model.removeHint == "The last project cannot be removed")
    }

    @Test func redetectMessageNamesWhatWasFound() {
        var project = ProjectFixture.exampleApp
        project.scheme = "ExampleApp"
        project.bundleID = ""

        #expect(ProjectSettingsRowMapper.redetectMessage(for: project) == "\(project.name): scheme ExampleApp, no bundle ID")
    }

    @Test func settingAFieldUpdatesIt() {
        let updated = ProjectSettingsRowMapper.project(ProjectFixture.devHub, setting: \.scheme, to: "DevHub Debug")

        #expect(updated.scheme == "DevHub Debug")
        #expect(updated.id == ProjectFixture.devHub.id)
    }
}
