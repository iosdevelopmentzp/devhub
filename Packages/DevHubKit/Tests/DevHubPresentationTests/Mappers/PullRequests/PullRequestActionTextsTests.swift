import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestActionTextsTests {
    @Test func textsNameTheRequestWithTheWordsOfTheHost() {
        #expect(PullRequestActionTexts.texts(for: .approve, number: 7, words: .gitHub) == PullRequestActionTexts(title: "Approve #7", done: "Approved #7", failed: "Cannot approve #7"))
        #expect(PullRequestActionTexts.texts(for: .rebase, number: 7, words: .gitHub) == PullRequestActionTexts(title: "Update #7", done: "Update of #7 started", failed: "Cannot update #7"))
        #expect(PullRequestActionTexts.texts(for: .rebase, number: 7, words: .gitLab) == PullRequestActionTexts(title: "Rebase !7", done: "Rebase of !7 started", failed: "Cannot rebase !7"))
        #expect(PullRequestActionTexts.texts(for: .mergeWhenPipelinePasses, number: 7, words: .gitHub).done == "#7 merges when the checks pass")
        #expect(PullRequestActionTexts.texts(for: .retryPipeline, number: 7, words: .gitLab).title == "Retry the pipeline of !7")
    }
}
