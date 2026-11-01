import Foundation
import Testing
import DevHubDomain
@testable import DevHubPresentation

@Suite struct XcodeOptionMapperTests {
    private let beta = XcodeInstallation(appPath: "/Applications/Xcode-beta.app", version: "26.2", build: nil)
    private let release = XcodeInstallation(appPath: "/Applications/Xcode.app", version: "26.1", build: nil)

    @Test func theDefaultNamesTheSystemXcodeThenEveryApp() {
        let options = XcodeOptionMapper.options(installations: [beta, release], systemDeveloperDir: release.developerDir, configDeveloperDir: nil, choice: nil)

        #expect(options == [
            XcodeOptionModel(id: "", title: "Default · Xcode 26.1 · Xcode.app"),
            XcodeOptionModel(id: "/Applications/Xcode-beta.app/Contents/Developer", title: "Xcode 26.2 · Xcode-beta.app"),
            XcodeOptionModel(id: "/Applications/Xcode.app/Contents/Developer", title: "Xcode 26.1 · Xcode.app"),
        ])
    }

    @Test func theDefaultNamesTheProjectConfigWhenItIsSet() {
        let options = XcodeOptionMapper.options(installations: [beta, release], systemDeveloperDir: release.developerDir, configDeveloperDir: "/Applications/Xcode-beta.app", choice: nil)

        #expect(options.first?.title == "project.json · Xcode 26.2 · Xcode-beta.app")
    }

    @Test func aChoiceThatIsNoLongerInstalledStaysVisible() {
        let options = XcodeOptionMapper.options(installations: [release], systemDeveloperDir: nil, configDeveloperDir: nil, choice: "/Applications/Xcode-old.app/Contents/Developer")

        #expect(options.first?.title == "Default · xcode-select")
        #expect(options.last == XcodeOptionModel(id: "/Applications/Xcode-old.app/Contents/Developer", title: "Not found · /Applications/Xcode-old.app/Contents/Developer"))
    }

    @Test func theSummarySaysWhichXcodeBuilds() {
        #expect(XcodeOptionMapper.summary(effective: beta.developerDir, systemDeveloperDir: release.developerDir, installations: [beta, release]) == "Builds use Xcode 26.2 · Xcode-beta.app (DEVELOPER_DIR)")
        #expect(XcodeOptionMapper.summary(effective: nil, systemDeveloperDir: release.developerDir, installations: [beta, release]) == "Builds use the Xcode of xcode-select: Xcode 26.1 · Xcode.app")
        #expect(XcodeOptionMapper.summary(effective: "/Opt/Xcode.app/Contents/Developer", systemDeveloperDir: nil, installations: []) == "Builds use /Opt/Xcode.app (DEVELOPER_DIR)")
    }
}
