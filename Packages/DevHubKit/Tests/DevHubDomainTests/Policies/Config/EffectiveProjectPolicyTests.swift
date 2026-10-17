import Testing
@testable import DevHubDomain

@Suite struct EffectiveProjectPolicyTests {
    private let project = Project(id: "app", name: "app", path: "/repo", scheme: "ExampleApp", bundleID: "com.example.app", identity: nil)

    @Test func detectionFillsWhatConfigLeavesOut() {
        let effective = EffectiveProjectPolicy.resolve(config: .empty, project: project, detectedSchemes: ["ExampleApp", "Widget"], detectedBaseBranch: "origin/develop")

        #expect(effective.name == "app")
        #expect(effective.kind == .xcode)
        #expect(effective.schemes == ["ExampleApp", "Widget"])
        #expect(effective.scheme == "ExampleApp")
        #expect(effective.configuration == "Debug")
        #expect(effective.baseBranch == "origin/develop")
        #expect(effective.bundleID == "com.example.app")
    }

    @Test func configWins() {
        let config = ProjectConfig(
            name: "Example App",
            xcode: XcodeConfig(scheme: "Widget", configuration: "Release", schemes: ["Widget"], bundleIDs: ["Widget/Release": "com.example.app.widget"]),
            git: GitConfig(baseBranch: "origin/main")
        )

        let effective = EffectiveProjectPolicy.resolve(config: config, project: project, detectedSchemes: ["ExampleApp"], detectedBaseBranch: "origin/develop")

        #expect(effective.name == "Example App")
        #expect(effective.schemes == ["Widget"])
        #expect(effective.scheme == "Widget")
        #expect(effective.bundleID == "com.example.app.widget")
        #expect(effective.baseBranch == "origin/main")
    }

    @Test func noSchemeMeansACommandProject() {
        let plain = Project(id: "tool", name: "tool", path: "/tool", scheme: "—", bundleID: "—", identity: nil)

        let effective = EffectiveProjectPolicy.resolve(config: .empty, project: plain, detectedSchemes: [], detectedBaseBranch: nil)

        #expect(effective.kind == .command)
        #expect(effective.bundleID == nil)
        #expect(effective.baseBranch == "origin/main")
        #expect(EffectiveProjectPolicy.resolve(config: ProjectConfig(git: GitConfig(remote: "upstream")), project: plain, detectedSchemes: [], detectedBaseBranch: nil).baseBranch == "upstream/main")
    }
}
