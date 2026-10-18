import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CopilotUsageParserTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func premiumRequestsFromEntitlementAndRemaining() throws {
        let json = #"{"copilot_plan":"business","quota_reset_date":"2026-11-01","quota_snapshots":{"premium_interactions":{"entitlement":300,"remaining":225,"unlimited":false}}}"#

        let usage = try CopilotUsageParser.parse(Data(json.utf8), now: now)

        #expect(usage.plan == "Business")
        #expect(usage.limits.map(\.id) == ["premium"])
        #expect(usage.limits.first?.usedFraction == 0.25)
        #expect(usage.limits.first?.resetsAt == (try? Date.ISO8601FormatStyle().year().month().day().parse("2026-11-01")))
        #expect(usage.updatedAt == now)
    }

    @Test func premiumRequestsFromPercentRemaining() throws {
        let json = #"{"quota_reset_date":"2026-11-01T00:00:00Z","quota_snapshots":{"premium_interactions":{"percent_remaining":40}}}"#

        let usage = try CopilotUsageParser.parse(Data(json.utf8), now: now)

        #expect(usage.plan == nil)
        #expect(usage.limits.first?.usedFraction == 0.6)
        #expect(usage.limits.first?.resetsAt == ISO8601.date(from: "2026-11-01T00:00:00Z"))
    }

    @Test func anUnlimitedPlanHasNoLimits() throws {
        let unlimited = try CopilotUsageParser.parse(Data(#"{"copilot_plan":"enterprise","quota_snapshots":{"premium_interactions":{"unlimited":true}}}"#.utf8), now: now)
        let noQuota = try CopilotUsageParser.parse(Data(#"{"copilot_plan":"free"}"#.utf8), now: now)

        #expect(unlimited.isUnlimited)
        #expect(unlimited.plan == "Enterprise")
        #expect(noQuota.isUnlimited)
    }

    @Test func anUnknownShapeIsMalformed() {
        #expect(throws: CopilotUsageError.malformedResponse) { try CopilotUsageParser.parse(Data("[]".utf8), now: now) }
        #expect(throws: CopilotUsageError.malformedResponse) { try CopilotUsageParser.parse(Data(#"{"login":"dev"}"#.utf8), now: now) }
        #expect(throws: CopilotUsageError.malformedResponse) { try CopilotUsageParser.parse(Data(#"{"quota_snapshots":{"premium_interactions":{}}}"#.utf8), now: now) }
    }
}
