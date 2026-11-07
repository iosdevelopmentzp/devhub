import Foundation
import Testing
@testable import DevHubDomain

@Suite struct RedactionPolicyTests {
    private let subjects = RedactionSubjects(
        organization: "example",
        repository: "app",
        host: "github.example.com",
        branches: ["feature/ABC-123-short-title", "main"],
        logins: ["alex", "sam"],
        homeFolder: "/Users/alex"
    )

    @Test func theSubjectsBecomePlaceholders() {
        let text = "gh/example/app feature/ABC-123-short-title into main by alex and sam at /Users/alex/Projects/app on github.example.com"

        let redacted = RedactionPolicy.redact(text, subjects: subjects, words: [])

        #expect(redacted == "gh/<org>/<repo> <branch-1> into <branch-2> by <user-1> and <user-2> at ~/Projects/<repo> on <host>")
    }

    @Test func wordsMatchWholeWordsWithoutCase() {
        #expect(RedactionPolicy.redact("App Example APP application app-store", subjects: subjects, words: []) == "<repo> <org> <repo> application <repo>-store")
    }

    @Test func aLongerBranchWinsOverItsPrefix() {
        let branches = RedactionSubjects(branches: ["main", "main-release"])

        #expect(RedactionPolicy.redact("main-release and main", subjects: branches, words: []) == "<branch-2> and <branch-1>")
    }

    @Test func denylistWordsAndPatternsAreRedacted() {
        let words: [RedactionWord] = [.word("Secret Corp"), .pattern("XYZ-[0-9]+")]

        let redacted = RedactionPolicy.redact("Secret corp ticket XYZ-42 and secret corporation xyz-1", subjects: RedactionSubjects(), words: words)

        #expect(redacted == "<redacted> ticket <redacted> and secret corporation <redacted>")
    }

    @Test func emptySubjectsChangeNothing() {
        let subjects = RedactionSubjects(organization: "", repository: nil, host: nil, branches: [""], logins: [], homeFolder: "")

        #expect(RedactionPolicy.redact("as it is", subjects: subjects, words: []) == "as it is")
    }

    @Test func linksEmailsAddressesAndTokensAreReplaced() {
        let token = "ghp_" + String(repeating: "a1B2", count: 9)
        let hash = String(repeating: "ab12", count: 10)
        let text = "see https://ci.example.com/pipelines/7?x=1, mail sam.lee@example.org, host 192.168.1.20, token \(token), sha \(hash), version 26.4.1"

        let redacted = RedactionPolicy.redact(text, subjects: RedactionSubjects(), words: [])

        #expect(redacted == "see <url>, mail <email>, host <ip>, token <secret>, sha <secret>, version 26.4.1")
    }

    @Test func theProjectFolderUserSchemeAndBundleAreReplaced() {
        let subjects = RedactionSubjects(
            homeFolder: "/Users/alex",
            userName: "alex",
            projectFolder: "/Users/alex/Projects/example-app",
            projectNames: ["Example App", "example-app"],
            schemes: ["ExampleApp"],
            bundleIDs: ["com.example.app"]
        )
        let text = "/Users/alex/Projects/example-app/Sources/A.swift and /Users/alex/Library by alex: Example App, scheme ExampleApp, bundle com.example.app, folder example-app"

        let redacted = RedactionPolicy.redact(text, subjects: subjects, words: [])

        #expect(redacted == "<project>/Sources/A.swift and ~/Library by <user>: <project>, scheme <scheme>, bundle <bundle>, folder <project>")
    }
}
