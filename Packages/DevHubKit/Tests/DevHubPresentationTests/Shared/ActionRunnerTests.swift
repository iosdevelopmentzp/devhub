import DevHubDomain
import DevHubMocks
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ActionRunnerTests {
    let activity = ActivityLog(events: [], store: InMemoryKeyValueStore())
    let operations = OperationLog()

    @Test func busyTitleIsSetSynchronously() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .git)
        #expect(runner.busyTitle == nil)

        runner.run("Fetch", detail: "origin") {}

        #expect(runner.busyTitle == "Fetch")
        try await waitUntil { runner.busyTitle == nil }
    }

    @Test func successLogsTitleAndDetail() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .git)

        runner.run("Fetch", detail: "origin") {}
        try await waitUntil { activity.events.isEmpty == false }

        let event = try #require(activity.events.first)
        #expect(event.title == "Fetch")
        #expect(event.detail == "origin")
        #expect(event.outcome == .success)
        #expect(runner.busyTitle == nil)
    }

    @Test func failureLogsDefaultTitleAndErrorDescription() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .git)

        runner.run("Push", detail: "origin") { throw Failure() }
        try await waitUntil { activity.events.isEmpty == false }

        let event = try #require(activity.events.first)
        #expect(event.title == "Push failed")
        #expect(event.detail == "rejected by remote")
        #expect(event.outcome == .failure)
        #expect(runner.busyTitle == nil)
    }

    @Test func failureUsesFailureTitleWhenGiven() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .git)

        runner.run("Push", detail: "origin", failureTitle: "Could not push") { throw Failure() }
        try await waitUntil { activity.events.isEmpty == false }

        #expect(activity.events.first?.title == "Could not push")
    }

    @Test func successCallsOnSuccessThenCompletion() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .git)
        let steps = Steps()

        runner.run(
            "Fetch",
            detail: "origin",
            onSuccess: { steps.items.append("success busy=\(runner.busyTitle ?? "nil")") },
            onFailure: { steps.items.append("failure") },
            completion: { steps.items.append("completion busy=\(runner.busyTitle ?? "nil")") },
            work: { steps.items.append("work busy=\(runner.busyTitle ?? "nil")") }
        )
        try await waitUntil { steps.items.count == 3 }

        #expect(steps.items == ["work busy=Fetch", "success busy=nil", "completion busy=nil"])
    }

    @Test func failureCallsOnFailureThenCompletion() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .git)
        let steps = Steps()

        runner.run(
            "Fetch",
            detail: "origin",
            onSuccess: { steps.items.append("success") },
            onFailure: { steps.items.append("failure busy=\(runner.busyTitle ?? "nil")") },
            completion: { steps.items.append("completion busy=\(runner.busyTitle ?? "nil")") },
            work: { throw Failure() }
        )
        try await waitUntil { steps.items.count == 2 }

        #expect(steps.items == ["failure busy=nil", "completion busy=nil"])
    }

    @Test func theWorkRunsInsideItsOperation() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .git)
        let steps = Steps()

        runner.run("Fetch", detail: "origin") {
            steps.items.append(OperationScope.current?.uuidString ?? "none")
        }
        try await waitUntil { operations.running.isEmpty }

        let record = try #require(operations.latest(at: .git))
        #expect(steps.items == [record.id.uuidString])
        #expect(record.title == "Fetch")
        #expect(record.status == .succeeded)
        #expect(record.canRetry)
    }

    @Test func aFailureEndsTheOperationWithTheMessage() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .changes)

        runner.run("Push", detail: "origin") { throw Failure() }
        try await waitUntil { operations.running.isEmpty }

        #expect(operations.latest(at: .changes)?.failureMessage == "rejected by remote")
    }

    @Test func retryRunsTheSameWorkAgain() async throws {
        let runner = ActionRunner(activity: activity, operations: operations, origin: .git)
        let steps = Steps()
        runner.run("Push", detail: "origin") {
            steps.items.append("push")
            throw Failure()
        }
        try await waitUntil { runner.busyTitle == nil && operations.running.isEmpty }
        let failed = try #require(operations.latest(at: .git))

        operations.retry(failed.id)
        try await waitUntil { steps.items.count == 2 && operations.running.isEmpty }

        #expect(operations.records.count == 2)
        #expect(operations.latest(at: .git)?.id != failed.id)
    }
}

private struct Failure: LocalizedError {
    var errorDescription: String? { "rejected by remote" }
}

private final class Steps {
    var items: [String] = []
}
