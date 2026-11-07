import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct ProductLocatorTests {
    private let directory: TemporaryDirectory
    private let locator: ProductLocator

    init() throws {
        directory = try TemporaryDirectory()
        locator = ProductLocator(derivedData: XcodeDerivedDataRepository(shell: ShellRunner(recorder: SpyCommandRecorder())))
    }

    @Test func readsBundleIDFromInfoPlist() throws {
        let app = try makeApp("Debug-iphonesimulator/App.app", bundleID: "com.example.app")

        #expect(locator.bundleID(ofApp: app) == "com.example.app")
    }

    @Test func bundleIDIsNilWithoutInfoPlist() throws {
        let app = directory.url.appendingPathComponent("Empty.app")
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)

        #expect(locator.bundleID(ofApp: app.path) == nil)
    }

    @Test func prefersAnExistingHintForTheConfiguration() throws {
        let release = try makeApp("Release-iphonesimulator/App.app", bundleID: "com.example.app")
        let debug = try makeApp("Debug-iphonesimulator/App.app", bundleID: "com.example.app")
        let missing = directory.path("Debug-iphonesimulator/Missing.app")
        let container = XcodeContainer(kind: .project, url: directory.url.appendingPathComponent("App.xcodeproj"))

        let path = locator.appPath(hints: [release, missing, debug], container: container, scheme: "App", configuration: "Debug")

        #expect(path == debug)
    }

    @Test func aPhysicalDeviceTakesTheIphoneosHint() throws {
        let simulator = try makeApp("Debug-iphonesimulator/App.app", bundleID: "com.example.app")
        let device = try makeApp("Debug-iphoneos/App.app", bundleID: "com.example.app")
        let container = XcodeContainer(kind: .project, url: directory.url.appendingPathComponent("App.xcodeproj"))

        let path = locator.appPath(hints: [simulator, device], container: container, scheme: "App", configuration: "Debug", isPhysicalDevice: true)

        #expect(path == device)
        #expect(ProductLocator.productsFolder(configuration: "Release", isPhysicalDevice: true) == "Release-iphoneos")
        #expect(ProductLocator.productsFolder(configuration: "Debug", isPhysicalDevice: false) == "Debug-iphonesimulator")
    }

    @Test func returnsNilWhenNoHintMatchesAndDerivedDataHasNoFolder() throws {
        let release = try makeApp("Release-iphonesimulator/App.app", bundleID: "com.example.app")
        let container = XcodeContainer(kind: .project, url: directory.url.appendingPathComponent("App.xcodeproj"))

        let path = locator.appPath(hints: [release], container: container, scheme: "App", configuration: "Debug")

        #expect(path == nil)
    }

    private func makeApp(_ relativePath: String, bundleID: String) throws -> String {
        let app = directory.url.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let plist = try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": bundleID], format: .xml, options: 0)
        try plist.write(to: app.appendingPathComponent("Info.plist"))
        return app.path
    }
}
