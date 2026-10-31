import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct InboxItemTextTests {
    private let item = InboxItem(id: "1", kind: .mention, title: "ABC-1: Title", actor: "sam", excerpt: nil, target: .pullRequest(iid: 12), webURL: nil, updatedAt: nil)

    @Test func titlesNameTheActorAndTheReference() {
        #expect(InboxItemText.title(for: item, words: .gitLab) == "sam mentioned you in !12")
        #expect(InboxItemText.title(for: with(kind: .mention, actor: nil), words: .gitHub) == "You were mentioned in #12")
        #expect(InboxItemText.title(for: with(kind: .reviewRequested), words: .gitHub) == "sam asked for your review on #12")
        #expect(InboxItemText.title(for: with(kind: .reviewRequested, actor: nil), words: .gitHub) == "Your review is requested on #12")
        #expect(InboxItemText.title(for: with(kind: .assigned, actor: nil), words: .gitHub) == "You were assigned #12")
        #expect(InboxItemText.title(for: with(kind: .comment, target: .issue(iid: 3)), words: .gitHub) == "sam commented on issue #3")
        #expect(InboxItemText.title(for: with(kind: .approvalRequired), words: .gitLab) == "sam needs your approval on !12")
        #expect(InboxItemText.title(for: with(kind: .checksFailed), words: .gitLab) == "Pipeline failed on !12")
        #expect(InboxItemText.title(for: with(kind: .other("state change"), actor: nil, target: .other), words: .gitHub) == "State change on ABC-1: Title")
    }

    @Test func kindTitlesAreShort() {
        #expect(InboxItemText.kindTitle(for: .mention, words: .gitHub) == "Mention")
        #expect(InboxItemText.kindTitle(for: .reviewRequested, words: .gitHub) == "Review requested")
        #expect(InboxItemText.kindTitle(for: .checksFailed, words: .gitHub) == "Checks failed")
        #expect(InboxItemText.kindTitle(for: .other("merge train removed"), words: .gitHub) == "Merge train removed")
    }

    @Test func theTargetIsTheRequestOrTheInbox() {
        #expect(InboxItemText.target(for: item) == .pullRequest(iid: 12))
        #expect(InboxItemText.target(for: with(kind: .assigned, target: .issue(iid: 3))) == .inbox)
        #expect(InboxItemText.target(for: with(kind: .assigned, target: .other)) == .inbox)
    }

    private func with(kind: InboxItem.Kind, actor: String? = "sam", target: InboxItem.Target = .pullRequest(iid: 12)) -> InboxItem {
        InboxItem(id: item.id, kind: kind, title: item.title, actor: actor, excerpt: nil, target: target, webURL: nil, updatedAt: nil)
    }
}
