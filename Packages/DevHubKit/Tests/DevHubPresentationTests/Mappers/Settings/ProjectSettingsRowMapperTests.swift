import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation
import DevHubTestSupport

@Suite struct ProjectSettingsRowMapperTests {
    @Test func selectedProjectWithDeviceTools() {
        let model = ProjectSettingsRowMapper.model(for: ProjectFixture.exampleApp, isSelected: true, projectCount: 2)

        #expect(model.id == "example-app")
        #expect(model.name == "ExampleApp")
        #expect(model.path == "/Users/dev/Projects/ExampleApp")
        #expect(model.icon == "shippingbox.fill")
        #expect(model.iconTint == .indigo)
        #expect(model.iconHint == "The project DevHub shows now")
        #expect(model.deviceToolsTag == TagModel(
            "device tools",
            tint: .indigo,
            systemImage: "person.text.rectangle",
            hint: "Device ID and environment per simulator are available for this app"
        ))
        #expect(model.canRemove)
        #expect(model.removeHint == "Remove from DevHub. Files stay on disk.")
        #expect(model.removeQuestion == "Remove ExampleApp from DevHub? The folder stays on disk.")
    }

    @Test func otherProjectWithoutDeviceTools() {
        let model = ProjectSettingsRowMapper.model(for: ProjectFixture.devHub, isSelected: false, projectCount: 2)

        #expect(model.icon == "shippingbox")
        #expect(model.iconTint == .secondary)
        #expect(model.iconHint == "Another project. Switch in the header.")
        #expect(model.deviceToolsTag == nil)
    }

    @Test func lastProjectCannotBeRemoved() {
        let model = ProjectSettingsRowMapper.model(for: ProjectFixture.exampleApp, isSelected: true, projectCount: 1)

        #expect(model.canRemove == false)
        #expect(model.removeHint == "The last project cannot be removed")
    }

    @Test func settingAFieldUpdatesIt() {
        let updated = ProjectSettingsRowMapper.project(ProjectFixture.devHub, setting: \.scheme, to: "DevHub Debug")

        #expect(updated.scheme == "DevHub Debug")
        #expect(updated.identity == nil)
        #expect(updated.id == ProjectFixture.devHub.id)
    }

    @Test func aNewBundleIDDropsTheIdentity() {
        let same = ProjectSettingsRowMapper.project(ProjectFixture.exampleApp, setting: \.bundleID, to: ProjectFixture.exampleApp.bundleID)
        let other = ProjectSettingsRowMapper.project(ProjectFixture.exampleApp, setting: \.bundleID, to: "com.example.other")

        #expect(same.identity == .example)
        #expect(other.identity == nil)
        #expect(other.bundleID == "com.example.other")
    }
}
