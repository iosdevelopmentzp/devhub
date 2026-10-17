import Testing
@testable import DevHubData

@Suite struct CommandFormatterTests {
    @Test(arguments: [
        ("status", "status"),
        ("--format=%(refname:short)", "--format=%(refname:short)"),
        ("a b", "'a b'"),
        ("tab\there", "'tab\there'"),
        ("it's", "'it'\\''s'"),
        ("say \"hi\"", "'say \"hi\"'"),
        ("$HOME", "'$HOME'"),
        ("`date`", "'`date`'"),
        ("a\\b", "'a\\b'"),
        ("line1\nline2", "'…script…'"),
        ("", "''"),
    ])
    func quotesArgument(argument: String, expected: String) {
        #expect(CommandFormatter.displayCommand("git", [argument]) == "git \(expected)")
    }

    @Test func joinsExecutableAndArgumentsWithSpaces() {
        #expect(CommandFormatter.displayCommand("xcrun", ["simctl", "boot", "ABC"]) == "xcrun simctl boot ABC")
    }

    @Test func shortensLongArguments() {
        let long = String(repeating: "q", count: 300)

        #expect(CommandFormatter.displayCommand("glab", ["api", long]) == "glab api \(String(repeating: "q", count: 160))…")
        #expect(CommandFormatter.displayCommand("glab", [String(repeating: "q", count: 160)]) == "glab \(String(repeating: "q", count: 160))")
    }

    @Test func leavesExecutableUnquoted() {
        #expect(CommandFormatter.displayCommand("/bin/my tool", []) == "/bin/my tool")
    }
}
