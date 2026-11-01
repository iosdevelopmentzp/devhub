import DevHubDomain
import DevHubMocks
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct AppDataPanelMapperTests {
    private let data = MockData.appData

    @Test func listsFoldersThenGroupContainers() {
        let model = AppDataPanelMapper.model(for: data, query: "")

        #expect(model.title == "App data of com.example.app")
        #expect(model.containerPath == data.container)
        #expect(model.folders.map(\.name) == ["Documents", "Library/Application Support", "Library/Caches", "Library/Preferences", "tmp", "group.com.example.app"])
        #expect(model.folders.last?.icon == "folder.badge.person.crop")
        #expect(model.folders.allSatisfy { $0.sizeText.isEmpty == false })
        #expect(model.databases.map(\.icon) == ["cylinder.split.1x2", "cylinder.split.1x2"])
    }

    @Test func oneSectionPerSuite() {
        let model = AppDataPanelMapper.model(for: data, query: "")

        #expect(model.sections.map(\.title) == ["User defaults · com.example.app", "User defaults · group.com.example.app"])
        #expect(model.sections.map(\.detail) == ["6 keys", "2 keys"])
        #expect(model.sections.first?.rows.count == 6)
        #expect(model.sections.allSatisfy { $0.emptyText == nil && $0.hiddenText == nil })
    }

    @Test func theQueryFiltersTheKeys() {
        let model = AppDataPanelMapper.model(for: data, query: "theme")

        #expect(model.sections[0].rows.isEmpty)
        #expect(model.sections[0].detail == "0 of 6 keys")
        #expect(model.sections[0].emptyText == "No key matches \"theme\"")
        #expect(model.sections[1].rows.map(\.key) == ["widgetTheme"])
        #expect(model.sections[1].detail == "1 of 2 keys")
    }

    @Test func anEmptySuiteSaysSo() {
        let suite = AppDefaultsSuite(name: "com.example.app", plistPath: "/p", entries: [])

        #expect(AppDataPanelMapper.section(suite, query: "").emptyText == "No keys yet")
    }

    @Test func longSuitesShowTheFirstRowsOnly() {
        let entries = (0..<(AppDataPanelMapper.rowLimit + 5)).map { AppDefault(key: "key\($0)", kind: .integer, text: "\($0)") }
        let section = AppDataPanelMapper.section(AppDefaultsSuite(name: "com.example.app", plistPath: "/p", entries: entries), query: "")

        #expect(section.rows.count == AppDataPanelMapper.rowLimit)
        #expect(section.hiddenText == "5 more keys. Search to narrow the list.")
    }

    @Test func aBooleanRowCanBeToggled() {
        let row = AppDataPanelMapper.row(AppDefault(key: "onboardingDone", kind: .bool, text: "true"))

        #expect(row.canEdit)
        #expect(row.toggleValue == .bool(false))
        #expect(row.toggleHint == "Set to false")
        #expect(row.kindTag.text == "bool")
        #expect(row.readOnlyHint == nil)
    }

    @Test func aDictionaryRowIsReadOnly() {
        let row = AppDataPanelMapper.row(AppDefault(key: "featureFlags", kind: .dictionary, text: "{a: true}"))

        #expect(row.canEdit == false)
        #expect(row.toggleValue == nil)
        #expect(row.kindTag.text == "dict")
        #expect(row.readOnlyHint?.contains("dict") == true)
    }

    @Test func anEmptyStringShowsQuotes() {
        let row = AppDataPanelMapper.row(AppDefault(key: "name", kind: .string, text: ""))

        #expect(row.valueText == "\"\"")
        #expect(row.editText == "")
    }

    @Test func theGroupToggleNamesTheGroups() {
        let model = AppDataPanelMapper.model(for: data, query: "")
        var withoutGroups = data
        withoutGroups.groups = []

        #expect(model.groupsToggleTitle == "Also clear the app group containers (group.com.example.app)")
        #expect(AppDataPanelMapper.model(for: withoutGroups, query: "").groupsToggleTitle == nil)
        #expect(model.resetConfirmation == "Reset the data of com.example.app?")
        #expect(model.resetWarnings.count == 3)
    }
}
