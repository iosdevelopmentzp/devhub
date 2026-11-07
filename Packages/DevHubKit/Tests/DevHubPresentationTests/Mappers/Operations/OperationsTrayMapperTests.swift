import Foundation
import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct OperationsTrayMapperTests {
    @Test func showsTheOperationsThatAreNotDismissedInStartOrder() {
        let hidden = record("Fetch", origin: .git, status: .succeeded, isDismissed: true)
        let running = record("Push", origin: .git, status: .running, isDismissed: false)
        let failed = record("Bootstrap", origin: .worktree("/tmp/a"), status: .failed("boom"), isDismissed: false)

        let cards = OperationsTrayMapper.cards(for: [hidden, running, failed], entries: [], origin: nil)

        #expect(cards.map(\.title) == ["Push", "Bootstrap failed"])
        #expect(cards.map(\.isRunning) == [true, false])
        #expect(cards.last?.message == "boom")
    }

    @Test func anOriginKeepsOnlyItsOperations() {
        let push = record("Push", origin: .git, status: .running, isDismissed: false)
        let bootstrap = record("Bootstrap", origin: .worktree("/tmp/a"), status: .running, isDismissed: false)

        let cards = OperationsTrayMapper.cards(for: [push, bootstrap], entries: [], origin: .worktree("/tmp/a"))

        #expect(cards.map(\.title) == ["Bootstrap"])
    }

    @Test func noOperationsGiveNoCards() {
        #expect(OperationsTrayMapper.cards(for: [], entries: [], origin: nil).isEmpty)
    }

    private func record(_ title: String, origin: OperationOrigin, status: OperationRecord.Status, isDismissed: Bool) -> OperationRecord {
        OperationRecord(
            id: UUID(),
            title: title,
            origin: origin,
            startedAt: Date(timeIntervalSince1970: 1_000),
            finishedAt: status == .running ? nil : Date(timeIntervalSince1970: 1_002),
            status: status,
            progressText: nil,
            fraction: nil,
            canRetry: false,
            canStop: false,
            isDismissed: isDismissed,
            isSeen: false,
            isOutputOpen: false
        )
    }
}
