import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct CustomTabMapperTests {
    private let clean = ConfigSample.action("clean")
    private let devices = ConfigSample.action("script:list-devices", run: .script("scripts/list-devices.sh"))
    private let placed = ConfigSample.action("placed", placements: [.tab("qa")])

    private var resolved: ResolvedConfig {
        ConfigSample.resolved([clean, devices, placed])
    }

    @Test func actionsAndSourcesBecomeSectionsInOrder() {
        let tab = TabConfig(id: "qa", title: "QA", sections: [
            TabSection(title: "Project", actions: ["clean", "builtin.terminal", "gone"]),
            TabSection(title: "Devices", source: TabSource(script: "scripts/list-devices.sh", refresh: "manual")),
        ])

        let sections = CustomTabMapper.sections(for: tab, resolved: resolved, placed: [])

        #expect(sections == [
            CustomTabSectionModel(id: 0, title: "Project", content: .actions([.config(clean), .builtin(.terminal)], missing: ["gone"])),
            CustomTabSectionModel(id: 3, title: "Devices", content: .source(devices, refresh: .manual)),
        ])
    }

    @Test func aMissingSourceScriptIsNamed() {
        let tab = TabConfig(id: "qa", title: "QA", sections: [TabSection(title: "Devices", source: TabSource(script: "scripts/none.sh"))])

        #expect(CustomTabMapper.sections(for: tab, resolved: resolved, placed: []).first?.content == .missingSource("scripts/none.sh"))
    }

    @Test func actionsPlacedOnTheTabAreAddedOnce() {
        let tab = TabConfig(id: "qa", title: "QA", sections: [TabSection(title: "Project", actions: ["clean"])])

        let sections = CustomTabMapper.sections(for: tab, resolved: resolved, placed: [.config(clean), .config(placed)])

        #expect(sections.last == CustomTabSectionModel(id: 1, title: "Actions", content: .actions([.config(placed)], missing: [])))
    }
}
