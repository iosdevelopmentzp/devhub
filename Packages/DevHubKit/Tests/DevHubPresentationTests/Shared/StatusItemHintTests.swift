import Testing
import DevHubDomain
@testable import DevHubPresentation

@Suite struct StatusItemHintTests {
    @Test func failedChecksNameTheRequests() {
        #expect(StatusItemHint.text(for: .ciFailed, failedRequests: [12], onHold: [:], words: .gitHub) == "The checks of your pull request #12 failed")
        #expect(StatusItemHint.text(for: .ciFailed, failedRequests: [14, 12], onHold: [:], words: .gitHub) == "The checks of 2 of your pull requests failed: #12, #14")
    }

    @Test func aWaitingJobNamesTheRequestAndTheJob() {
        #expect(StatusItemHint.text(for: .ciWaiting, failedRequests: [], onHold: [7: ["approve-release"]], words: .gitLab) == "!7 waits for an approval of approve-release")
        #expect(StatusItemHint.text(for: .ciWaiting, failedRequests: [], onHold: [7: ["approve"], 9: ["deploy"]], words: .gitHub) == "#7 waits for an approval of approve, and 1 more pull request")
    }

    @Test func aQuietIconHasNoHint() {
        #expect(StatusItemHint.text(for: .idle, failedRequests: [], onHold: [:], words: .gitHub) == nil)
        #expect(StatusItemHint.text(for: .building, failedRequests: [], onHold: [:], words: .gitHub) == nil)
    }
}
