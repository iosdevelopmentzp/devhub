import Testing
@testable import DevHubDomain

@Suite struct InboxChangePolicyTests {
    private func item(_ id: String) -> InboxItem {
        InboxItem(id: id, kind: .mention, title: "T", actor: "sam", excerpt: nil, target: .pullRequest(iid: 1), webURL: nil, updatedAt: nil)
    }

    @Test func onlyItemsWithANewIDAreNew() {
        let before = [item("1"), item("2")]
        let after = [item("2"), item("3"), item("4")]

        #expect(InboxChangePolicy.newItems(from: before, to: after) == [item("3"), item("4")])
        #expect(InboxChangePolicy.newItems(from: after, to: before) == [item("1")])
        #expect(InboxChangePolicy.newItems(from: before, to: before).isEmpty)
        #expect(InboxChangePolicy.newItems(from: [], to: before) == before)
    }
}
