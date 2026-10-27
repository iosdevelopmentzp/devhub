import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct ProjectSwitchMapperTests {
    @Test func theFirstNineProjectsGetADigitInListOrder() {
        let projects = (1...10).map { Project(id: "p\($0)", name: "Project \($0)", path: "/p/\($0)", scheme: "", bundleID: "") }

        let items = ProjectSwitchMapper.items(projects: projects, selectedID: "p2")

        #expect(items.map(\.digit) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", nil])
        #expect(items[0].shortcutText == "⌃⌘1")
        #expect(items[9].shortcutText == nil)
        #expect(items.filter(\.isSelected).map(\.id) == ["p2"])
    }
}
