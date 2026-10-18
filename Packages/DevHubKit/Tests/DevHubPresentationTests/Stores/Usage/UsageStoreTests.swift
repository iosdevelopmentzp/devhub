import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct UsageStoreTests {
    private let harness = StoreHarness()
    private let fresh = ClaudeUsage(plan: "Max", limits: [UsageLimit(id: "five_hour", title: "5 hours", usedFraction: 0.4, resetsAt: nil)], updatedAt: .now)
    private let stale = ClaudeUsage(plan: "Max", limits: [], updatedAt: Date(timeIntervalSince1970: 0))

    private var store: UsageStore {
        harness.usage
    }

    @Test func refreshSetsTheUsage() async {
        harness.spies.usage.fetchResult = .success(fresh)

        await store.refresh()

        #expect(store.usage == fresh)
        #expect(store.error == nil)
        #expect(store.isRefreshing == false)
    }

    @Test func aFailedRefreshSetsTheErrorAndKeepsTheUsage() async {
        let failure = TestError.scripted("boom")
        harness.spies.usage.fetchResult = .success(fresh)
        await store.refresh()
        harness.spies.usage.fetchResult = .failure(failure)

        await store.refresh()

        #expect(store.error == failure.localizedDescription)
        #expect(store.usage == fresh)
    }

    @Test func refreshIfStaleSkipsAFreshValue() async {
        store.usage = fresh

        await store.refreshIfStale()

        #expect(harness.spies.usage.calls.isEmpty)
    }

    @Test func refreshIfStaleFetchesAStaleValue() async {
        store.usage = stale
        harness.spies.usage.fetchResult = .success(fresh)

        await store.refreshIfStale()

        #expect(harness.spies.usage.calls == [.fetch])
        #expect(store.usage == fresh)
    }

    @Test func refreshIfStaleFetchesWithoutAValue() async {
        await store.refreshIfStale()

        #expect(harness.spies.usage.calls == [.fetch])
    }

    @Test func copilotUsageIsReadNextToClaude() async {
        let copilot = CopilotUsage(plan: "Business", limits: [UsageFixture.week], updatedAt: UsageFixture.now)
        harness.spies.copilotUsage.fetchResult = .success(copilot)

        await store.refresh()

        #expect(store.copilot == copilot)
        #expect(store.copilotError == nil)
        #expect(harness.spies.copilotUsage.calls == [.fetch])
        #expect(harness.spies.usage.calls.count == 1)
    }

    @Test func aCopilotFailureDoesNotTouchClaude() async {
        harness.spies.usage.fetchResult = .success(fresh)
        harness.spies.copilotUsage.fetchResult = .failure(CopilotUsageError.rejected)

        await store.refresh()

        #expect(store.usage == fresh)
        #expect(store.error == nil)
        #expect(store.copilot == nil)
        #expect(store.copilotError == CopilotUsageError.rejected.localizedDescription)
    }
}
