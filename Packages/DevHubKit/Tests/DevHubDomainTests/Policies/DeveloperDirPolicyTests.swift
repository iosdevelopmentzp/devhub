import Testing
@testable import DevHubDomain

@Suite struct DeveloperDirPolicyTests {
    @Test func anAppPathPointsIntoItsDeveloperFolder() {
        #expect(DeveloperDirPolicy.developerDir(of: "/Applications/Xcode-beta.app") == "/Applications/Xcode-beta.app/Contents/Developer")
        #expect(DeveloperDirPolicy.developerDir(of: "/Applications/Xcode.app/") == "/Applications/Xcode.app/Contents/Developer")
        #expect(DeveloperDirPolicy.developerDir(of: " /Applications/Xcode.app/Contents/Developer ") == "/Applications/Xcode.app/Contents/Developer")
    }

    @Test func aTildeIsExpanded() {
        #expect(DeveloperDirPolicy.developerDir(of: "~/Apps/Xcode.app").hasSuffix("/Apps/Xcode.app/Contents/Developer"))
        #expect(DeveloperDirPolicy.developerDir(of: "~/Apps/Xcode.app").hasPrefix("~") == false)
    }

    @Test func theAppPathComesBackFromTheDeveloperFolder() {
        #expect(DeveloperDirPolicy.appPath(ofDeveloperDir: "/Applications/Xcode.app/Contents/Developer") == "/Applications/Xcode.app")
        #expect(DeveloperDirPolicy.appPath(ofDeveloperDir: "/Library/Developer/CommandLineTools") == "/Library/Developer/CommandLineTools")
    }

    @Test func theChoiceWinsOverTheConfig() {
        #expect(DeveloperDirPolicy.effective(choice: "/Applications/Xcode-beta.app", config: "/Applications/Xcode.app") == "/Applications/Xcode-beta.app/Contents/Developer")
        #expect(DeveloperDirPolicy.effective(choice: nil, config: "/Applications/Xcode.app") == "/Applications/Xcode.app/Contents/Developer")
        #expect(DeveloperDirPolicy.effective(choice: "  ", config: "/Applications/Xcode.app") == "/Applications/Xcode.app/Contents/Developer")
        #expect(DeveloperDirPolicy.effective(choice: nil, config: nil) == nil)
        #expect(DeveloperDirPolicy.effective(choice: "", config: "") == nil)
    }

    @Test func onlyXcodeToolsGetTheFolder() {
        #expect(DeveloperDirPolicy.applies(to: "xcodebuild"))
        #expect(DeveloperDirPolicy.applies(to: "xcrun"))
        #expect(DeveloperDirPolicy.applies(to: "xed"))
        #expect(DeveloperDirPolicy.applies(to: "git") == false)
        #expect(DeveloperDirPolicy.applies(to: "open") == false)
    }
}
