import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct BuildOutputParserTests {
    @Test(arguments: [
        ("SwiftCompile normal arm64 /src/File.swift (in target 'App' from project 'App')", "Compiling · App"),
        ("CompileC /build/main.o /src/main.m normal arm64 (in target 'Legacy' from project 'App')", "Compiling · Legacy"),
        ("CompileAssetCatalog /build/App.app /src/Assets.xcassets (in target 'App' from project 'App')", "Compiling assets · App"),
        ("Ld /build/App.app/App normal (in target 'App' from project 'App')", "Linking · App"),
        ("CodeSign /build/App.app (in target 'App' from project 'App')", "Signing · App"),
        ("ProcessInfoPlistFile /build/App.app/Info.plist /src/Info.plist", "Processing Info.plist"),
        ("PhaseScriptExecution Run\\ SwiftLint /build/Script.sh", "Running script"),
        ("Resolve Package Graph", "Resolving packages"),
        ("Resolved source packages:", "Resolving packages"),
    ])
    func stepFromLine(line: String, expected: String) {
        #expect(BuildOutputParser.step(from: line) == expected)
    }

    @Test(arguments: [
        "",
        "    cd /src",
        "\tSwiftCompile indented",
        "Build settings from command line:",
        "note: Using codesigning identity override",
    ])
    func stepIgnoresOtherLines(line: String) {
        #expect(BuildOutputParser.step(from: line) == nil)
    }

    @Test(arguments: [
        ("/Users/me/App/Sources/File.swift:10:5: error: cannot find 'x' in scope", "File.swift:10:5: error: cannot find 'x' in scope"),
        ("  error: no such module 'Foo'  ", "error: no such module 'Foo'"),
        ("xcodebuild: error: Unable to find a destination", "xcodebuild: error: Unable to find a destination"),
    ])
    func errorFromLine(line: String, expected: String) {
        #expect(BuildOutputParser.error(from: line) == expected)
    }

    @Test(arguments: ["warning: deprecated", "Compiling error.swift", "error:missing space"])
    func errorIgnoresOtherLines(line: String) {
        #expect(BuildOutputParser.error(from: line) == nil)
    }

    @Test(arguments: [
        ("Touch /DD/Build/Products/Debug-iphonesimulator/App.app (in target 'App' from project 'App')", "/DD/Build/Products/Debug-iphonesimulator/App.app"),
        ("CodeSign /Users/me/Derived\\ Data/Debug-iphonesimulator/My\\ App.app (in target 'App' from project 'App')", "/Users/me/Derived Data/Debug-iphonesimulator/My App.app"),
        ("Validate /DD/App.app", "/DD/App.app"),
        ("RegisterExecutionPolicyException /DD/App.app (in target 'App' from project 'App')", "/DD/App.app"),
    ])
    func appPathFromLine(line: String, expected: String) {
        #expect(BuildOutputParser.appPath(from: line) == expected)
    }

    @Test(arguments: [
        "Ld /DD/App.app",
        "Touch /DD/Widget.appex",
        "Touch relative/App.app",
        "Touch",
        "",
    ])
    func appPathIgnoresOtherLines(line: String) {
        #expect(BuildOutputParser.appPath(from: line) == nil)
    }

    @Test func issuesKeepTheFileLineColumnAndSeverity() {
        #expect(BuildOutputParser.issue(from: "/Users/dev/App/LoginView.swift:42:9: error: cannot find 'viewModel' in scope") == BuildIssue(
            severity: .error,
            path: "/Users/dev/App/LoginView.swift",
            line: 42,
            column: 9,
            message: "cannot find 'viewModel' in scope"
        ))
        #expect(BuildOutputParser.issue(from: "/Users/dev/App/Old.swift:7: warning: 'foo' is deprecated")?.severity == .warning)
        #expect(BuildOutputParser.issue(from: "/Users/dev/App/Old.swift:7: warning: 'foo' is deprecated")?.column == nil)
    }

    @Test func anErrorWithoutAFileIsKeptAndOtherLinesAreNot() {
        #expect(BuildOutputParser.issue(from: "xcodebuild: error: Unable to find a destination") == BuildIssue(severity: .error, path: nil, line: nil, column: nil, message: "Unable to find a destination"))
        #expect(BuildOutputParser.issue(from: "CompileSwift normal arm64 /Users/dev/App/LoginView.swift") == nil)
        #expect(BuildOutputParser.issue(from: "note: Using codesigning identity override") == nil)
    }
}
