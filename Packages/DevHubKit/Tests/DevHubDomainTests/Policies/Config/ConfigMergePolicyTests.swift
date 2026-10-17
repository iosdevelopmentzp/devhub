import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ConfigMergePolicyTests {
    @Test func theUserLayerWinsFieldByField() {
        let resolved = ConfigMergePolicy.resolve([
            ConfigFixture.layer(.project, project: ConfigFixture.projectJSON),
            ConfigFixture.layer(.user, project: #"{ "git": { "baseBranch": "origin/develop" } }"#),
        ])

        #expect(resolved.project.git?.baseBranch == "origin/develop")
        #expect(resolved.project.name == "Example App")
        #expect(resolved.issues.isEmpty)
    }

    @Test func actionsMergeByIDAndAHigherLayerReplaces() {
        let resolved = ConfigMergePolicy.resolve([
            ConfigFixture.layer(.global, actions: [ConfigFixture.cleanAction]),
            ConfigFixture.layer(.project, actions: [#"{ "id": "clean", "title": "Clean here", "run": { "terminal": "make clean" } }"#]),
        ])

        #expect(resolved.actions.map(\.config.title) == ["Clean here"])
        #expect(resolved.actions.first?.origin.layer == .project)
    }

    @Test func oneBadItemIsOneIssueAndTheRestLoads() {
        let resolved = ConfigMergePolicy.resolve([ConfigFixture.layer(.project, actions: [ConfigFixture.twoActions])])

        #expect(resolved.actions.map(\.id) == ["open-ci"])
        #expect(resolved.issues.map(\.fileName) == ["actions/0.json [1]"])
    }

    @Test func aBrokenProjectFileEmptiesOnlyThatLayer() {
        let resolved = ConfigMergePolicy.resolve([
            ConfigFixture.layer(.global, project: #"{ "name": "Global" }"#),
            ConfigFixture.layer(.project, project: "{ broken"),
        ])

        #expect(resolved.project.name == "Global")
        #expect(resolved.issues.count == 1)
        #expect(resolved.issues.first?.layer == .project)
    }

    @Test func actionsSortByLayerRankThenTitle() {
        let resolved = ConfigMergePolicy.resolve([
            ConfigFixture.layer(.global, actions: [#"{ "id": "a", "title": "Alpha", "run": { "open": "x" } }"#]),
            ConfigFixture.layer(.user, actions: [#"{ "id": "z", "title": "Zulu", "run": { "open": "x" } }"#, #"{ "id": "b", "title": "Bravo", "run": { "open": "x" } }"#]),
        ])

        #expect(resolved.actions.map(\.id) == ["b", "z", "a"])
    }

    @Test func tabsAreReplacedByID() {
        let resolved = ConfigMergePolicy.resolve([
            ConfigFixture.layer(.global, tabs: [ConfigFixture.tab]),
            ConfigFixture.layer(.project, tabs: [#"{ "id": "qa", "title": "QA here" }"#]),
        ])

        #expect(resolved.tabs.map(\.title) == ["QA here"])
    }

    @Test func aHeaderScriptWithoutExecuteBitIsListedAsBlocked() {
        let script = ScriptFile(name: "scripts/regenerate.sh", head: ConfigFixture.header, isExecutable: false)
        let plain = ScriptFile(name: "scripts/notes.txt", head: "notes", isExecutable: false)

        let resolved = ConfigMergePolicy.resolve([ConfigFixture.layer(.project, scripts: [script, plain])])

        #expect(resolved.actions.map(\.id) == ["script:regenerate"])
        #expect(resolved.actions.first?.origin.isExecutable == false)
        #expect(resolved.actions.first?.origin.isHeaderScript == true)
        #expect(resolved.issues.count == 2)
    }

    @Test func readIssuesAreKeptAndLayersAreListed() {
        var layer = ConfigFixture.layer(.project)
        layer.readIssues = [ConfigIssue(layer: .project, fileName: "actions", message: "Cannot read")]

        let resolved = ConfigMergePolicy.resolve([layer])

        #expect(resolved.issues.map(\.message) == ["Cannot read"])
        #expect(resolved.layers == [ConfigLayerInfo(layer: .project, directory: "/project/.devhub", exists: true)])
    }
}
