import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct InboxRowMapperTests {
    private let mention = InboxItem(id: "901", kind: .mention, title: "ABC-123: Login", actor: "sam", excerpt: "@alex check", target: .pullRequest(iid: 12), webURL: URL(string: "https://gitlab.example.com/team/app/-/merge_requests/12"), updatedAt: .now)
    private let assigned = InboxItem(id: "903", kind: .assigned, title: "Crash on cold start", actor: "lee", excerpt: nil, target: .issue(iid: 31), webURL: nil, updatedAt: nil)

    @Test func aMentionOnARequestOpensInDevHub() {
        let model = InboxRowMapper.model(for: mention, isBusy: true, words: .gitLab)

        #expect(model.id == "901")
        #expect(model.icon == "at")
        #expect(model.iconTint == .purple)
        #expect(model.iconHint == "Mention")
        #expect(model.title == "sam mentioned you in !12")
        #expect(model.detail == "ABC-123: Login · @alex check")
        #expect(model.dateText != nil)
        #expect(model.webURL == mention.webURL)
        #expect(model.pullRequestIID == 12)
        #expect(model.openHint == "Open !12 in DevHub")
        #expect(model.doneHint == "Mark as done on GitLab: the to-do leaves the Inbox")
        #expect(model.isBusy)
    }

    @Test func anIssueHasNoDevHubOpenAction() {
        let model = InboxRowMapper.model(for: assigned, isBusy: false, words: .gitHub)

        #expect(model.icon == "person")
        #expect(model.iconTint == .blue)
        #expect(model.title == "lee assigned you issue #31")
        #expect(model.detail == "Crash on cold start")
        #expect(model.dateText == nil)
        #expect(model.pullRequestIID == nil)
        #expect(model.openHint == nil)
        #expect(model.doneHint == "Mark as done on GitHub: the thread leaves the Inbox")
    }

    @Test func modelsFilterByTheQueryAndMarkTheBusyOnes() {
        let models = InboxRowMapper.models(for: [mention, assigned], busyIDs: ["903"], query: "", words: .gitLab)
        let filtered = InboxRowMapper.models(for: [mention, assigned], busyIDs: [], query: "crash", words: .gitLab)

        #expect(models.map(\.isBusy) == [false, true])
        #expect(filtered.map(\.id) == ["903"])
    }
}
