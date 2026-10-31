import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ActivityEventTests {
    @Test func encodesAndDecodesEveryFieldIncludingTheTarget() throws {
        let events = [
            ActivityEvent(id: UUID(), title: "Built App", detail: "Debug", date: Date(timeIntervalSince1970: 1_700_000_000), outcome: .success, kind: .build, target: .build),
            ActivityEvent(id: UUID(), title: "#3 merged", detail: "", date: Date(timeIntervalSince1970: 1_700_000_100), outcome: .info, kind: .requestClosed, target: .pullRequest(iid: 3)),
            ActivityEvent(id: UUID(), title: "Tests", detail: "", date: Date(timeIntervalSince1970: 1_700_000_200), outcome: .failure, kind: .tests, target: .worktree(path: "/w")),
            ActivityEvent(id: UUID(), title: "Review", detail: "", date: Date(timeIntervalSince1970: 1_700_000_300), outcome: .info, kind: .reviewRequests, target: .reviewQueue),
            ActivityEvent(id: UUID(), title: "Plain", detail: "", date: Date(timeIntervalSince1970: 1_700_000_400), outcome: .info)
        ]

        let data = try JSONEncoder().encode(events)
        let decoded = try JSONDecoder().decode([ActivityEvent].self, from: data)

        #expect(decoded == events)
    }

    @Test func anEventWithoutKindAndTargetStillDecodes() throws {
        let json = #"[{"id":"6BA7B810-9DAD-11D1-80B4-00C04FD430C8","title":"Old","detail":"d","date":0,"outcome":{"info":{}}}]"#

        let decoded = try JSONDecoder().decode([ActivityEvent].self, from: Data(json.utf8))

        #expect(decoded.first?.title == "Old")
        #expect(decoded.first?.kind == nil)
        #expect(decoded.first?.target == nil)
    }
}
