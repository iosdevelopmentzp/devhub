import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ActionRunnerTests {
    let activity = ActivityLog(events: [])

    @Test func busyTitleIsSetSynchronously() async throws {
        let runner = ActionRunner(activity: activity)
        #expect(runner.busyTitle == nil)

        runner.run("Fetch", detail: "origin") {}

        #expect(runner.busyTitle == "Fetch")
        try await waitUntil { runner.busyTitle == nil }
    }

    @Test func successLogsTitleAndDetail() async throws {
        let runner = ActionRunner(activity: activity)

        runner.run("Fetch", detail: "origin") {}
        try await waitUntil { activity.events.isEmpty == false }

        let event = try #require(activity.events.first)
        #expect(event.title == "Fetch")
        #expect(event.detail == "origin")
        #expect(event.outcome == .success)
        #expect(runner.busyTitle == nil)
    }

    @Test func failureLogsDefaultTitleAndErrorDescription() async throws {
        let runner = ActionRunner(activity: activity)

        runner.run("Push", detail: "origin") { throw Failure() }
        try await waitUntil { activity.events.isEmpty == false }

        let event = try #require(activity.events.first)
        #expect(event.title == "Push failed")
        #expect(event.detail == "rejected by remote")
        #expect(event.outcome == .failure)
        #expect(runner.busyTitle == nil)
    }

    @Test func failureUsesFailureTitleWhenGiven() async throws {
        let runner = ActionRunner(activity: activity)

        runner.run("Push", detail: "origin", failureTitle: "Could not push") { throw Failure() }
        try await waitUntil { activity.events.isEmpty == false }

        #expect(activity.events.first?.title == "Could not push")
    }

    @Test func successCallsOnSuccessThenCompletion() async throws {
        let runner = ActionRunner(activity: activity)
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
        let runner = ActionRunner(activity: activity)
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
}

private struct Failure: LocalizedError {
    var errorDescription: String? { "rejected by remote" }
}

private final class Steps {
    var items: [String] = []
}
