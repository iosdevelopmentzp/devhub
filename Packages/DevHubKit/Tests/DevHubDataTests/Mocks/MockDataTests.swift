import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct MockDataTests {
    @Test func staticsAreNotEmpty() {
        #expect(MockData.recentEvents.isEmpty == false)
        #expect(MockData.aiSessions.isEmpty == false)
        #expect(MockData.installedApps.isEmpty == false)
        #expect(MockData.projects.isEmpty == false)
        #expect(MockData.simulatorGroups.flatMap(\.simulators).isEmpty == false)
        #expect(MockData.usage.limits.isEmpty == false)
        #expect(MockData.worktrees.isEmpty == false)
        #expect(MockData.derivedDataSizes.isEmpty == false)
    }

    @Test func worktreesStartWithTheMainCheckout() {
        #expect(MockData.worktrees.first?.kind == .main)
        #expect(MockData.worktrees.dropFirst().allSatisfy { $0.kind != .main })
    }

    @Test func identitiesPointAtMockSimulators() {
        let simulatorIDs = Set(MockData.simulatorGroups.flatMap(\.simulators).map(\.id))

        #expect(Set(MockData.installedApps.keys).isSubset(of: simulatorIDs))
    }

    @Test func agoCountsBackFromNow() {
        #expect(MockData.ago(minutes: 1, hours: 1, days: 1) == MockData.now.addingTimeInterval(-(60 + 3_600 + 86_400)))
        #expect(MockData.ago() == MockData.now)
    }
}
