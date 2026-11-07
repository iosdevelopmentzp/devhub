import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct StatusMenuMapperTests {
    private let app = Project(id: "app", name: "Example App", path: "/p/example-app", scheme: "ExampleApp", bundleID: "com.example.app")
    private let tools = Project(id: "tools", name: "Tools", path: "/p/tools", scheme: "", bundleID: "")

    @Test func severalProjectsAreListedWithTheSelectedOneMarked() {
        let items = StatusMenuMapper.items(projects: [app, tools], selectedID: "tools", isKeepAwakeOn: true)

        #expect(items == [
            .show, .separator,
            .projectsHeader,
            .project(id: "app", title: "Example App", isSelected: false),
            .project(id: "tools", title: "Tools", isSelected: true),
            .separator,
            .keepAwake(isOn: true), .separator, .checkForUpdates, .settings, .separator, .quit,
        ])
    }

    @Test func oneProjectGivesNoProjectList() {
        let items = StatusMenuMapper.items(projects: [app], selectedID: "app", isKeepAwakeOn: false)

        #expect(items == [.show, .separator, .keepAwake(isOn: false), .separator, .checkForUpdates, .settings, .separator, .quit])
    }
}
