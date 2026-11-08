import Testing
@testable import DevHubDomain

@Suite struct ExampleConfigTests {
    @Test func theExampleDecodesWithoutIssues() {
        let files = ExampleConfig.files
        let layer = ConfigLayerFiles(
            layer: .project,
            directory: "/repo/.devhub",
            exists: true,
            projectFile: files.first { $0.path == "project.json" }.map { ConfigFile(name: $0.path, text: $0.text) },
            actionFiles: files.filter { $0.path.hasPrefix("actions/") }.map { ConfigFile(name: $0.path, text: $0.text) },
            scriptFiles: files.filter { $0.path.hasPrefix("scripts/") }.map { ScriptFile(name: $0.path, head: $0.text, isExecutable: $0.isExecutable) },
            tabFiles: files.filter { $0.path.hasPrefix("tabs/") }.map { ConfigFile(name: $0.path, text: $0.text) }
        )

        let resolved = ConfigMergePolicy.resolve([layer])

        #expect(resolved.issues.isEmpty)
        #expect(resolved.project.name == "Example App")
        #expect(resolved.actions.isEmpty == false)
        #expect(resolved.tabs.isEmpty == false)
        #expect(resolved.project.launch?.identity?.variable == "APP_DEVICE_ID")
        #expect(resolved.project.launch?.profiles?.first?.upstream == "https://api-qa.example.com")
        #expect(resolved.project.launch?.profiles?.last?.isProduction == true)
        #expect(resolved.project.network == NetworkConfig(baseURLVariable: "APP_BASE_URL", mocksFolder: "Tests/Mocks", sourceScript: "network/source.sh"))
    }

    @Test func scriptsAreExecutable() {
        #expect(ExampleConfig.files.filter { $0.path.hasSuffix(".sh") }.allSatisfy { $0.isExecutable })
    }
}
