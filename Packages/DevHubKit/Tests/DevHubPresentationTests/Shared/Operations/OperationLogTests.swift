import Foundation
import Testing
import DevHubDomain
@testable import DevHubPresentation

@Suite struct OperationLogTests {
    private let log = OperationLog()

    @Test func startAddsARunningOperationAtItsOrigin() {
        let id = log.start("Push", at: .git, retry: nil, stop: nil)

        let record = log.latest(at: .git)
        #expect(record?.id == id)
        #expect(record?.isRunning == true)
        #expect(record?.canRetry == false)
        #expect(record?.canStop == false)
        #expect(log.running.map(\.id) == [id])
        #expect(log.latest(at: .changes) == nil)
    }

    @Test func finishStatesEndTheOperation() {
        let pushed = log.start("Push", at: .git, retry: nil, stop: {})
        let failed = log.start("Commit", at: .changes, retry: nil, stop: nil)
        let stopped = log.start("Clean", at: .action("clean"), retry: nil, stop: nil)

        log.succeed(pushed)
        log.fail(failed, message: "nothing to commit")
        log.cancel(stopped)

        #expect(log.record(pushed)?.status == .succeeded)
        #expect(log.record(pushed)?.canStop == false)
        #expect(log.record(pushed)?.finishedAt != nil)
        #expect(log.record(failed)?.failureMessage == "nothing to commit")
        #expect(log.record(stopped)?.status == .cancelled)
        #expect(log.running.isEmpty)
    }

    @Test func performRunsTheWorkInsideTheOperationAndReturnsItsValue() async throws {
        var seen: UUID?

        let value = try await log.perform("Create worktree", at: .worktrees, retry: nil) {
            seen = OperationScope.current
            return 42
        }

        let record = try #require(log.latest(at: .worktrees))
        #expect(value == 42)
        #expect(seen == record.id)
        #expect(record.status == .succeeded)
        #expect(record.canRetry == false)
    }

    @Test func performEndsTheOperationWithTheErrorAndRethrows() async {
        await #expect(throws: PerformFailure.self) {
            try await log.perform("Fetch", at: .worktrees, retry: {}) {
                throw PerformFailure()
            }
        }

        #expect(log.latest(at: .worktrees)?.failureMessage == "offline")
        #expect(log.latest(at: .worktrees)?.canRetry == true)
    }

    @Test func performMarksACancellationAsStopped() async {
        await #expect(throws: CancellationError.self) {
            try await log.perform("Bootstrap", at: .worktree("/repo/wt"), retry: nil) {
                throw CancellationError()
            }
        }

        #expect(log.latest(at: .worktree("/repo/wt"))?.status == .cancelled)
    }

    @Test func progressIsKeptOnTheOperation() {
        let id = log.start("Regenerate", at: .action("gen"), retry: nil, stop: nil)

        log.setProgress(of: id, text: "Step 2 of 3", fraction: 0.6)

        #expect(log.record(id)?.progressText == "Step 2 of 3")
        #expect(log.record(id)?.fraction == 0.6)
    }

    @Test func aNewOperationHidesTheFinishedOneOfTheSameOrigin() {
        let first = log.start("Fetch", at: .git, retry: nil, stop: nil)
        log.fail(first, message: "offline")
        let other = log.start("Commit", at: .changes, retry: nil, stop: nil)
        log.succeed(other)

        let second = log.start("Pull", at: .git, retry: nil, stop: nil)

        #expect(log.record(first)?.isDismissed == true)
        #expect(log.record(other)?.isDismissed == false)
        #expect(log.latest(at: .git)?.id == second)
    }

    @Test func dismissHidesTheCardAndMarksItSeen() {
        let id = log.start("Fetch", at: .git, retry: nil, stop: nil)
        log.fail(id, message: "offline")
        #expect(log.unseenFailureCount == 1)

        log.dismiss(id)

        #expect(log.latest(at: .git) == nil)
        #expect(log.unseenFailureCount == 0)
        #expect(log.records.count == 1)
    }

    @Test func toggleExpandedFlipsTheCardAndDismissClosesIt() {
        let id = log.start("Fetch", at: .git, retry: nil, stop: nil)
        let other = log.start("Push", at: .git, retry: nil, stop: nil)

        log.toggleExpanded(id)
        #expect(log.expandedID == id)
        log.toggleExpanded(other)
        #expect(log.expandedID == other)
        log.toggleExpanded(other)
        #expect(log.expandedID == nil)

        log.toggleExpanded(id)
        log.fail(id, message: "offline")
        log.dismiss(id)
        #expect(log.expandedID == nil)

        log.toggleExpanded(other)
        log.succeed(other)
        log.clearFinished()
        #expect(log.expandedID == nil)
    }

    @Test func retryRunsTheClosureOnlyAfterTheEnd() {
        var retries = 0
        let id = log.start("Push", at: .git, retry: { retries += 1 }, stop: nil)

        log.retry(id)
        #expect(retries == 0)

        log.fail(id, message: "rejected")
        log.retry(id)

        #expect(retries == 1)
        #expect(log.record(id)?.isDismissed == true)
    }

    @Test func stopRunsTheClosureWhileRunning() {
        var stops = 0
        let id = log.start("Script", at: .action("x"), retry: nil, stop: { stops += 1 })

        log.stop(id)
        log.succeed(id)
        log.stop(id)

        #expect(stops == 1)
    }

    @Test func toggleOutputFlipsTheFlag() {
        let id = log.start("Fetch", at: .git, retry: nil, stop: nil)

        log.toggleOutput(of: id)
        #expect(log.record(id)?.isOutputOpen == true)
        log.toggleOutput(of: id)

        #expect(log.record(id)?.isOutputOpen == false)
    }

    @Test func markAllSeenClearsTheUnseenFailures() {
        let first = log.start("Fetch", at: .git, retry: nil, stop: nil)
        let second = log.start("Commit", at: .changes, retry: nil, stop: nil)
        log.fail(first, message: "offline")
        log.fail(second, message: "conflicts")
        #expect(log.unseenFailureCount == 2)

        log.markAllSeen()

        #expect(log.unseenFailureCount == 0)
    }

    @Test func removeAndClearKeepRunningOperations() {
        let running = log.start("Script", at: .action("x"), retry: nil, stop: nil)
        let done = log.start("Fetch", at: .git, retry: nil, stop: nil)
        let other = log.start("Commit", at: .changes, retry: nil, stop: nil)
        log.succeed(done)
        log.succeed(other)

        log.remove(running)
        log.remove(done)
        #expect(log.records.map(\.id) == [running, other])

        log.clearFinished()

        #expect(log.records.map(\.id) == [running])
    }

    @Test func onlyTheLastFinishedOperationsAreKept() {
        let running = log.start("Script", at: .action("long"), retry: nil, stop: nil)
        let finished = (0..<(OperationLog.finishedLimit + 5)).map { index in
            let id = log.start("Fetch \(index)", at: .git, retry: nil, stop: nil)
            log.succeed(id)
            return id
        }

        #expect(log.records.count == OperationLog.finishedLimit + 1)
        #expect(log.record(running) != nil)
        #expect(log.record(finished[0]) == nil)
        #expect(log.record(finished.last ?? UUID()) != nil)
        #expect(log.newestFirst.first?.id == finished.last)
    }
}

private struct PerformFailure: LocalizedError {
    var errorDescription: String? { "offline" }
}
