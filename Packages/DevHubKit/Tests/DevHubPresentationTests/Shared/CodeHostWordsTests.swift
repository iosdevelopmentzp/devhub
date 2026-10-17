import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct CodeHostWordsTests {
    @Test func eachKindHasItsWords() {
        #expect(CodeHostWords.gitHub.requestsTitle == "Pull Requests")
        #expect(CodeHostWords.gitLab.requestsTitle == "Merge Requests")
        #expect(CodeHostWords.gitHub.reference(12) == "#12")
        #expect(CodeHostWords.gitLab.reference(12) == "!12")
        #expect(CodeHostWords.gitHub.openTitle == "Open in GitHub")
        #expect(CodeHostWords.gitLab.tool == "glab")
    }

    @Test func anUnknownHostUsesNeutralWords() {
        let words = CodeHostWords(kind: nil)

        #expect(words.requestsTitle == "Pull Requests")
        #expect(words.openTitle == "Open in Browser")
        #expect(words.hostTitle == "The code host")
    }

    @Test func checkStatusesReadAsWords() {
        #expect(CodeHostWords.gitHub.status(.success) == "passed")
        #expect(CodeHostWords.gitLab.status(.success) == "success")
        #expect(CodeHostWords.gitHub.checks("is running", "are running") == "Checks are running")
    }
}
