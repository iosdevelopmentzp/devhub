import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct ClaudeUsageParserTests {
    private let now = Date(timeIntervalSince1970: 1_767_000_000)

    @Test func ordersFixedLimitsThenModelLimits() throws {
        let usage = try ClaudeUsageParser.parse(ClaudeUsageFixture.json, plan: "max", now: now)

        #expect(usage.limits.map(\.id) == ["five_hour", "seven_day", "seven_day_claude_code", "seven_day_opus"])
        #expect(usage.limits.map(\.title) == ["Session", "Week · all", "Week · Claude Code", "Week · Opus"])
    }

    @Test func dividesUtilizationByOneHundred() throws {
        let usage = try ClaudeUsageParser.parse(ClaudeUsageFixture.json, plan: nil, now: now)
        let fractions = usage.limits.map(\.usedFraction)

        #expect(zip(fractions, [0.42, 0.10, 0.03, 0.055]).allSatisfy { abs($0 - $1) < 0.000_001 })
    }

    @Test func readsResetDates() throws {
        let usage = try ClaudeUsageParser.parse(ClaudeUsageFixture.json, plan: nil, now: now)

        #expect(usage.limits.map(\.resetsAt) == [
            Date(timeIntervalSince1970: 1_767_323_045),
            nil,
            nil,
            Date(timeIntervalSince1970: 1_767_830_400),
        ])
    }

    @Test func skipsOAuthAppsLimit() throws {
        let usage = try ClaudeUsageParser.parse(ClaudeUsageFixture.json, plan: nil, now: now)

        #expect(usage.limits.contains { $0.id == "seven_day_oauth_apps" } == false)
    }

    @Test func addsScopedWeeklyLimitsAfterFlatOnes() throws {
        let usage = try ClaudeUsageParser.parse(ClaudeUsageFixture.scoped, plan: nil, now: now)

        #expect(usage.limits.map(\.id) == ["five_hour", "seven_day", "seven_day_opus", "seven_day_fable", "seven_day_claude_code"])
        #expect(usage.limits.map(\.title) == ["Session", "Week · all", "Week · Opus", "Week · Fable", "Week · Claude Code"])
    }

    @Test func readsPercentAndResetOfScopedLimit() throws {
        let usage = try ClaudeUsageParser.parse(ClaudeUsageFixture.scoped, plan: nil, now: now)
        let fable = try #require(usage.limits.first { $0.id == "seven_day_fable" })

        #expect(abs(fable.usedFraction - 0.07) < 0.000_001)
        #expect(fable.resetsAt == Date(timeIntervalSince1970: 1_767_830_400))
    }

    @Test func keepsFlatValueWhenScopedLimitRepeatsIt() throws {
        let usage = try ClaudeUsageParser.parse(ClaudeUsageFixture.scoped, plan: nil, now: now)
        let opus = try #require(usage.limits.first { $0.id == "seven_day_opus" })

        #expect(abs(opus.usedFraction - 0.055) < 0.000_001)
    }

    @Test func capitalizesPlanAndKeepsTheClock() throws {
        let usage = try ClaudeUsageParser.parse(ClaudeUsageFixture.json, plan: "max", now: now)

        #expect(usage.plan == "Max")
        #expect(usage.updatedAt == now)
    }

    @Test func defaultPlanName() throws {
        #expect(try ClaudeUsageParser.parse(ClaudeUsageFixture.json, plan: nil, now: now).plan == "Claude")
    }

    @Test(arguments: [ClaudeUsageFixture.noLimits, ClaudeUsageFixture.notAnObject])
    func withoutLimitsThrowsMalformedResponse(data: Data) {
        let error = #expect(throws: ClaudeUsageError.self) {
            try ClaudeUsageParser.parse(data, plan: nil, now: now)
        }
        guard case .malformedResponse? = error else {
            Issue.record("Expected .malformedResponse, got \(String(describing: error))")
            return
        }
    }

    @Test func invalidJSONThrows() {
        #expect(throws: (any Error).self) {
            try ClaudeUsageParser.parse(Data("{".utf8), plan: nil, now: now)
        }
    }
}
