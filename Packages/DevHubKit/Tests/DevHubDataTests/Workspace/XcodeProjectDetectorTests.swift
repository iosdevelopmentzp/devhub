import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct XcodeProjectDetectorTests {
    private let directory: TemporaryDirectory
    private let detector = XcodeProjectDetector()

    init() throws {
        directory = try TemporaryDirectory()
    }

    @Test func readsSchemeAndShortestAppBundleID() throws {
        let folder = directory.url.appendingPathComponent("MyApp")
        _ = try directory.write("<Scheme/>", to: "MyApp/MyApp.xcodeproj/xcshareddata/xcschemes/MyApp Dev.xcscheme")
        _ = try directory.write("""
        PRODUCT_BUNDLE_IDENTIFIER = "com.example.myapp.tests";
        PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp.widget.Widget;
        PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp.staging;
        PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp;
        PRODUCT_BUNDLE_IDENTIFIER = "$(BASE_ID)";
        PRODUCT_BUNDLE_IDENTIFIER = com.example.myappTests;
        """, to: "MyApp/MyApp.xcodeproj/project.pbxproj")

        let project = detector.project(at: folder)

        #expect(project.name == "MyApp")
        #expect(project.scheme == "MyApp Dev")
        #expect(project.bundleID == "com.example.myapp")
        #expect(project.identity == nil)
    }

    @Test func fallsBackToContainerNameThenFolderName() throws {
        let withProject = directory.url.appendingPathComponent("WithProject")
        try FileManager.default.createDirectory(at: withProject.appendingPathComponent("Container.xcodeproj"), withIntermediateDirectories: true)
        let empty = directory.url.appendingPathComponent("Empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)

        #expect(detector.project(at: withProject).scheme == "Container")
        #expect(detector.project(at: empty).scheme == "Empty")
        #expect(detector.project(at: empty).bundleID == "")
    }

    @Test func gitRepositoryNeedsADotGitEntry() throws {
        _ = try directory.write("gitdir: /elsewhere", to: "Linked/.git")
        try FileManager.default.createDirectory(at: directory.url.appendingPathComponent("Plain"), withIntermediateDirectories: true)

        #expect(detector.isGitRepository(directory.url.appendingPathComponent("Linked")))
        #expect(detector.isGitRepository(directory.url.appendingPathComponent("Plain")) == false)
    }
}
