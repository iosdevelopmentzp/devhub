import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct XcodeContainerTests {
    private let directory: TemporaryDirectory

    init() throws {
        directory = try TemporaryDirectory()
    }

    @Test func workspaceArguments() {
        let container = XcodeContainer(kind: .workspace, url: URL(fileURLWithPath: "/src/App.xcworkspace"))
        #expect(container.xcodebuildArguments == ["-workspace", "/src/App.xcworkspace"])
    }

    @Test func projectArguments() {
        let container = XcodeContainer(kind: .project, url: URL(fileURLWithPath: "/src/App.xcodeproj"))
        #expect(container.xcodebuildArguments == ["-project", "/src/App.xcodeproj"])
    }

    @Test func locatePrefersWorkspace() throws {
        try makeFolder("App.xcodeproj")
        try makeFolder("App.xcworkspace")

        let container = try XcodeContainer.locate(in: directory.url.path)

        #expect(container.kind == .workspace)
        #expect(container.url.lastPathComponent == "App.xcworkspace")
    }

    @Test func locateFindsProject() throws {
        try makeFolder("App.xcodeproj")
        _ = try directory.write("", to: "README.md")

        let container = try XcodeContainer.locate(in: directory.url.path)

        #expect(container.kind == .project)
        #expect(container.url.lastPathComponent == "App.xcodeproj")
    }

    @Test func locateThrowsWithoutContainer() throws {
        _ = try directory.write("", to: "Package.swift")
        let path = directory.url.path

        let error = try #require(throws: BuildError.self) {
            try XcodeContainer.locate(in: path)
        }
        guard case .noXcodeContainer(let folder) = error else {
            Issue.record("Expected .noXcodeContainer, got \(error)")
            return
        }
        #expect(folder == path)
    }

    @Test func projectSchemesFromSharedAndUserData() throws {
        try scheme("App.xcodeproj/xcshareddata/xcschemes/App.xcscheme")
        try scheme("App.xcodeproj/xcshareddata/xcschemes/App 10.xcscheme")
        try scheme("App.xcodeproj/xcuserdata/me.xcuserdatad/xcschemes/App 2.xcscheme")
        try scheme("App.xcodeproj/xcuserdata/me.xcuserdatad/xcschemes/xcschememanagement.plist")
        try scheme("App.xcodeproj/xcuserdata/other.xcuserdatad/xcschemes/Dev.xcscheme")

        let container = try XcodeContainer.locate(in: directory.url.path)

        #expect(container.schemeNames() == ["App", "App 2", "App 10", "Dev"])
    }

    @Test func workspaceSchemesIncludeSiblingProjects() throws {
        try scheme("App.xcworkspace/xcshareddata/xcschemes/Workspace.xcscheme")
        try scheme("App.xcodeproj/xcshareddata/xcschemes/App.xcscheme")
        try scheme("Pods.xcodeproj/xcshareddata/xcschemes/Pods.xcscheme")
        try scheme("Pods.xcodeproj/xcuserdata/me.xcuserdatad/xcschemes/App.xcscheme")

        let container = try XcodeContainer.locate(in: directory.url.path)

        #expect(container.schemeNames() == ["App", "Pods", "Workspace"])
    }

    @Test func projectWithoutSchemes() throws {
        try makeFolder("App.xcodeproj")

        #expect(try XcodeContainer.locate(in: directory.url.path).schemeNames().isEmpty)
    }

    private func makeFolder(_ name: String) throws {
        try FileManager.default.createDirectory(at: directory.url.appendingPathComponent(name), withIntermediateDirectories: true)
    }

    private func scheme(_ relativePath: String) throws {
        _ = try directory.write("<Scheme/>", to: relativePath)
    }
}
