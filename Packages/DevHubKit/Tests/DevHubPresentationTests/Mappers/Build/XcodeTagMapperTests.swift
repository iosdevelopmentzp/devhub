import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct XcodeTagMapperTests {
    private let beta = XcodeInstallation(appPath: "/Applications/Xcode-beta.app", version: "26.2", build: "17C5013c")
    private let release = XcodeInstallation(appPath: "/Applications/Xcode.app", version: "26.1", build: nil)

    @Test func theChoiceWinsThenTheConfigThenTheSystemXcode() {
        let chosen = XcodeTagMapper.tag(choice: beta.developerDir, configDeveloperDir: release.appPath, systemDeveloperDir: release.developerDir, installations: [beta, release])
        let config = XcodeTagMapper.tag(choice: nil, configDeveloperDir: release.appPath, systemDeveloperDir: beta.developerDir, installations: [beta, release])
        let system = XcodeTagMapper.tag(choice: "", configDeveloperDir: nil, systemDeveloperDir: release.developerDir, installations: [beta, release])

        #expect(chosen == TagModel("Xcode 26.2", tint: .secondary, hint: "Builds, simctl and xed use Xcode 26.2 (17C5013c) at /Applications/Xcode-beta.app, chosen in Settings → Projects."))
        #expect(config == TagModel("Xcode 26.1", tint: .secondary, hint: "Builds, simctl and xed use Xcode 26.1 at /Applications/Xcode.app, from xcode.developerDir in .devhub/project.json. Change it in Settings → Projects."))
        #expect(system == TagModel("Xcode 26.1", tint: .secondary, hint: "Builds, simctl and xed use Xcode 26.1 at /Applications/Xcode.app, the Xcode of xcode-select. Change it in Settings → Projects."))
    }

    @Test func anXcodeThatSpotlightDoesNotListShowsItsAppName() {
        let tag = XcodeTagMapper.tag(choice: "/Opt/Xcode-old.app", configDeveloperDir: nil, systemDeveloperDir: nil, installations: [release])

        #expect(tag?.text == "Xcode-old")
        #expect(tag?.hint == "Builds, simctl and xed use /Opt/Xcode-old.app, chosen in Settings → Projects.")
    }

    @Test func noKnownXcodeMeansNoTag() {
        #expect(XcodeTagMapper.tag(choice: nil, configDeveloperDir: nil, systemDeveloperDir: nil, installations: [release]) == nil)
    }
}
