import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct XcodeInstallationParserTests {
    @Test func spotlightOutputKeepsAppsOutsideTheTrashOnce() {
        let output = """
        /Applications/Xcode.app
        /Applications/Xcode-beta.app
        /Users/alex/.Trash/Xcode-old.app
        /Applications/Xcode.app

        /Volumes/Tools/Xcode 25.app
        """

        #expect(XcodeInstallationParser.appPaths(fromSpotlight: output) == [
            "/Applications/Xcode.app",
            "/Applications/Xcode-beta.app",
            "/Volumes/Tools/Xcode 25.app",
        ])
    }

    @Test func theVersionPlistGivesTheVersionAndTheBuild() {
        let installation = XcodeInstallationParser.installation(
            appPath: "/Applications/Xcode.app",
            versionPlist: ["CFBundleShortVersionString": "26.1", "ProductBuildVersion": "17B55"]
        )

        #expect(installation == XcodeInstallation(appPath: "/Applications/Xcode.app", version: "26.1", build: "17B55"))
        #expect(installation?.developerDir == "/Applications/Xcode.app/Contents/Developer")
    }

    @Test func anAppWithoutAVersionIsLeftOut() {
        #expect(XcodeInstallationParser.installation(appPath: "/Applications/Xcode.app", versionPlist: nil) == nil)
        #expect(XcodeInstallationParser.installation(appPath: "/Applications/Xcode.app", versionPlist: ["ProductBuildVersion": "17B55"]) == nil)
    }

    @Test func newerVersionsComeFirst() {
        let sorted = XcodeInstallationParser.sorted([
            XcodeInstallation(appPath: "/Applications/Xcode-9.app", version: "9.4", build: nil),
            XcodeInstallation(appPath: "/Applications/Xcode.app", version: "26.1", build: nil),
            XcodeInstallation(appPath: "/Applications/Xcode-beta.app", version: "26.2", build: nil),
        ])

        #expect(sorted.map(\.version) == ["26.2", "26.1", "9.4"])
    }

    @Test func theRepositoryReadsTheVersionFileOfAnApp() throws {
        let folder = try TemporaryDirectory()
        let plist = try PropertyListSerialization.data(fromPropertyList: ["CFBundleShortVersionString": "26.2", "ProductBuildVersion": "17C5013c"], format: .xml, options: 0)
        _ = try folder.write(String(decoding: plist, as: UTF8.self), to: "Xcode-beta.app/Contents/version.plist")

        let installation = SpotlightXcodeInstallationRepository.installation(at: folder.path("Xcode-beta.app"))

        #expect(installation?.version == "26.2")
        #expect(installation?.build == "17C5013c")
    }

    @Test func theRepositoryReadsTheVersionFileFromADeveloperDir() async throws {
        let folder = try TemporaryDirectory()
        let plist = try PropertyListSerialization.data(fromPropertyList: ["CFBundleShortVersionString": "26.1"], format: .xml, options: 0)
        _ = try folder.write(String(decoding: plist, as: UTF8.self), to: "Xcode.app/Contents/version.plist")
        let repository = SpotlightXcodeInstallationRepository(shell: ShellRunner(recorder: SpyCommandRecorder()))

        let installation = try await repository.installation(atDeveloperDir: folder.path("Xcode.app/Contents/Developer"))

        #expect(installation == XcodeInstallation(appPath: folder.path("Xcode.app"), version: "26.1", build: nil))
    }
}
