import DevHubDomain
import Testing

@Suite struct GitHiddenFilePolicyTests {
    @Test func aFileInsideTheCheckoutGetsItsRelativePath() {
        #expect(GitHiddenFilePolicy.relativePath(of: "/Users/dev/example-app/Config/Local.xcconfig", in: "/Users/dev/example-app") == "Config/Local.xcconfig")
        #expect(GitHiddenFilePolicy.relativePath(of: "/Users/dev/example-app/a b.plist", in: "/Users/dev/example-app/") == "a b.plist")
    }

    @Test func aFileOutsideTheCheckoutHasNoPath() {
        #expect(GitHiddenFilePolicy.relativePath(of: "/Users/dev/example-app-2/a.plist", in: "/Users/dev/example-app") == nil)
        #expect(GitHiddenFilePolicy.relativePath(of: "/Users/dev/example-app", in: "/Users/dev/example-app") == nil)
    }
}
