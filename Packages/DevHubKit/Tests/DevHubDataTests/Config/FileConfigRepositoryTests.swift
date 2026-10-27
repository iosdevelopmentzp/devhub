import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct FileConfigRepositoryTests {
    private let home: TemporaryDirectory
    private let project: TemporaryDirectory
    private let repository: FileConfigRepository

    init() throws {
        home = try TemporaryDirectory()
        project = try TemporaryDirectory()
        repository = FileConfigRepository(home: home.url, pollInterval: .milliseconds(50))
    }

    @Test func readsTheThreeLayers() async throws {
        _ = try project.write(#"{ "name": "Example App", "git": { "baseBranch": "origin/main" } }"#, to: ".devhub/project.json")
        _ = try project.write(#"{ "id": "clean", "title": "Clean", "run": { "terminal": "make clean" } }"#, to: ".devhub/actions/clean.json")
        _ = try home.write(#"{ "git": { "baseBranch": "origin/develop" } }"#, to: ".devhub/projects/\(project.url.lastPathComponent)/project.json")
        _ = try home.write(#"{ "id": "global", "title": "Global", "run": { "open": "https://example.com" } }"#, to: ".devhub/actions/global.json")
        let script = try project.write("#!/bin/sh\n# devhub: title = Hello\necho hi\n", to: ".devhub/scripts/hello.sh")
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)

        let resolved = await repository.load(projectPath: project.url.path)

        #expect(resolved.issues.isEmpty)
        #expect(resolved.project.name == "Example App")
        #expect(resolved.project.git?.baseBranch == "origin/develop")
        #expect(Set(resolved.actions.map(\.id)) == ["clean", "global", "script:hello"])
        #expect(resolved.action(id: "script:hello")?.origin.isExecutable == true)
        #expect(resolved.layers.map(\.layer) == [.global, .project, .user])
        #expect(resolved.layers.map(\.exists) == [true, true, true])
    }

    @Test func aMissingFolderIsNotAnIssue() async {
        let resolved = await repository.load(projectPath: project.url.path)

        #expect(resolved.issues.isEmpty)
        #expect(resolved.actions.isEmpty)
        #expect(resolved.layers.map(\.exists) == [false, false, false])
    }

    @Test func theGlobalLayerHasNoProjectFile() async throws {
        _ = try home.write(#"{ "name": "Global" }"#, to: ".devhub/project.json")

        #expect(await repository.load(projectPath: project.url.path).project.name == nil)
    }

    @Test func createExampleWritesTheFilesAndRefusesTwice() async throws {
        let folder = try await repository.createExample(projectPath: project.url.path)

        #expect(folder == project.url.path + "/.devhub")
        #expect(FileManager.default.fileExists(atPath: folder + "/project.json"))
        #expect(FileManager.default.isExecutableFile(atPath: folder + "/scripts/sim-status.sh"))
        #expect(await repository.load(projectPath: project.url.path).issues.isEmpty)
        await #expect(throws: ConfigError.exampleExists(folder)) {
            try await repository.createExample(projectPath: project.url.path)
        }
    }

    @Test func existingFolderPrefersTheProjectLayer() async throws {
        #expect(await repository.existingFolder(projectPath: project.url.path) == nil)

        _ = try home.write("{}", to: ".devhub/project.json")
        #expect(await repository.existingFolder(projectPath: project.url.path) == home.url.path + "/.devhub")

        _ = try project.write("{}", to: ".devhub/project.json")
        #expect(await repository.existingFolder(projectPath: project.url.path) == project.url.path + "/.devhub")
    }

    @Test func createStarterWritesTheProjectFileOnceAndTheConfigLoads() async throws {
        let json = StarterConfigPolicy.projectJSON(StarterConfigFacts(name: "Example App", scheme: "ExampleApp", bundleID: "com.example.app", remote: "origin", hostKind: .github, baseBranch: "main"))

        let file = try await repository.createStarter(projectPath: project.url.path, projectJSON: json)

        #expect(file == project.url.path + "/.devhub/project.json")
        let loaded = await repository.load(projectPath: project.url.path)
        #expect(loaded.issues.isEmpty)
        #expect(loaded.project.name == "Example App")
        await #expect(throws: ConfigError.starterExists(file)) {
            try await repository.createStarter(projectPath: project.url.path, projectJSON: json)
        }
    }
}
