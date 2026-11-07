import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIRedactionPolicyTests {
    private let subjects = CIRedactionSubjects(
        organization: "example",
        repository: "app",
        host: "github.example.com",
        branches: ["feature/ABC-123-short-title", "main"],
        logins: ["alex", "sam"],
        homeFolder: "/Users/alex"
    )

    @Test func theSubjectsBecomePlaceholders() {
        let text = "gh/example/app feature/ABC-123-short-title into main by alex and sam at /Users/alex/Projects/app on github.example.com"

        let redacted = CIRedactionPolicy.redact(text, subjects: subjects, words: [])

        #expect(redacted == "gh/<org>/<repo> <branch-1> into <branch-2> by <user-1> and <user-2> at ~/Projects/<repo> on <host>")
    }

    @Test func wordsMatchWholeWordsWithoutCase() {
        #expect(CIRedactionPolicy.redact("App Example APP application app-store", subjects: subjects, words: []) == "<repo> <org> <repo> application <repo>-store")
    }

    @Test func aLongerBranchWinsOverItsPrefix() {
        let branches = CIRedactionSubjects(branches: ["main", "main-release"])

        #expect(CIRedactionPolicy.redact("main-release and main", subjects: branches, words: []) == "<branch-2> and <branch-1>")
    }

    @Test func denylistWordsAndPatternsAreRedacted() {
        let words: [RedactionWord] = [.word("Secret Corp"), .pattern("XYZ-[0-9]+")]

        let redacted = CIRedactionPolicy.redact("Secret corp ticket XYZ-42 and secret corporation xyz-1", subjects: CIRedactionSubjects(), words: words)

        #expect(redacted == "<redacted> ticket <redacted> and secret corporation <redacted>")
    }

    @Test func emptySubjectsChangeNothing() {
        let subjects = CIRedactionSubjects(organization: "", repository: nil, host: nil, branches: [""], logins: [], homeFolder: "")

        #expect(CIRedactionPolicy.redact("as it is", subjects: subjects, words: []) == "as it is")
    }
}
