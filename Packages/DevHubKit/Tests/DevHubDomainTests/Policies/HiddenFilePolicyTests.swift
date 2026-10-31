import Testing
@testable import DevHubDomain

@Suite struct HiddenFilePolicyTests {
    private let patterns = HiddenFilePolicy.suggestedPatterns

    @Test(arguments: [
        "Packages/App/Tests/AppTests/LoginTests.swift",
        "AppTests/LoginTests.swift",
        "Sources/Login/LoginViewTests.swift",
        "App.xcodeproj/project.pbxproj",
        "App.xcodeproj/xcshareddata/xcschemes/App.xcscheme",
        "Package.resolved",
        "Podfile.lock",
    ])
    func theSuggestionsMatchTestsProjectAndLockFiles(path: String) {
        #expect(HiddenFilePolicy.isHidden(path, patterns: patterns))
    }

    @Test(arguments: [
        "Sources/Login/LoginView.swift",
        "Sources/TestSupport/Fixtures.swift",
        "Podfile",
        "docs/testing.md",
    ])
    func otherFilesAreNotSuggested(path: String) {
        #expect(HiddenFilePolicy.isHidden(path, patterns: patterns) == false)
    }

    @Test func aPatternMatchesTheWholePathOrTheFileName() {
        #expect(HiddenFilePolicy.isHidden("a/b/c.generated.swift", patterns: ["*.generated.swift"]))
        #expect(HiddenFilePolicy.isHidden("Pods/Alamofire/Source/Request.swift", patterns: ["Pods/*"]))
        #expect(HiddenFilePolicy.isHidden("Pods/Alamofire/Source/Request.swift", patterns: ["*/Source/*"]))
        #expect(HiddenFilePolicy.isHidden("a/b/c.swift", patterns: ["Pods/*"]) == false)
        #expect(HiddenFilePolicy.isHidden("a/b/c.swift", patterns: []) == false)
    }

    @Test func hiddenPathsKeepOnlyTheMatches() {
        let paths = ["App/Login.swift", "AppTests/LoginTests.swift", "Package.resolved"]

        #expect(HiddenFilePolicy.hiddenPaths(in: paths, patterns: patterns) == ["AppTests/LoginTests.swift", "Package.resolved"])
        #expect(HiddenFilePolicy.hiddenPaths(in: paths, patterns: []).isEmpty)
    }

    @Test func chosenPathsAreHiddenNextToThePatterns() {
        let paths = ["App/Login.swift", "App/Generated.swift", "Package.resolved"]

        let hidden = HiddenFilePolicy.hiddenPaths(in: paths, patterns: ["*.resolved"], chosen: ["App/Generated.swift", "Other/Gone.swift"])

        #expect(hidden == ["App/Generated.swift", "Package.resolved"])
    }

    @Test func theSuggestionsLeaveOutHiddenFilesAndKeepTheOrder() {
        let paths = ["Podfile.lock", "App/Login.swift", "AppTests/LoginTests.swift", "App.xcodeproj/project.pbxproj"]

        #expect(HiddenFilePolicy.suggestedPaths(in: paths, hidden: ["AppTests/LoginTests.swift"]) == ["Podfile.lock", "App.xcodeproj/project.pbxproj"])
        #expect(HiddenFilePolicy.suggestedPaths(in: ["App/Login.swift"], hidden: []).isEmpty)
    }
}
