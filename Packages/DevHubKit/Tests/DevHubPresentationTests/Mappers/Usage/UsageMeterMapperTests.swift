import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct UsageMeterMapperTests {
    let now = UsageFixture.now

    @Test func copiesTheLimit() {
        let model = UsageMeterMapper.model(for: UsageFixture.session, now: now)

        #expect(model.id == "five_hour")
        #expect(model.title == "Session")
        #expect(model.percentText == "64%")
        #expect(model.fraction == 0.64)
    }

    @Test func levelTintThresholds() {
        let table: [(Double, Tint?)] = [
            (0, nil),
            (0.59, nil),
            (0.6, .orange),
            (0.84, .orange),
            (0.85, .red),
            (1, .red)
        ]

        for (fraction, tint) in table {
            var limit = UsageFixture.session
            limit.usedFraction = fraction
            #expect(UsageMeterMapper.model(for: limit, now: now).levelTint == tint)
        }
    }

    @Test func resetText() {
        var limit = UsageFixture.session
        limit.resetsAt = nil
        #expect(UsageMeterMapper.model(for: limit, now: now).resetText == "No reset scheduled")

        limit.resetsAt = now.addingTimeInterval(2 * 3_600)
        let soon = UsageMeterMapper.model(for: limit, now: now).resetText
        #expect(soon.hasPrefix("Resets in "))
        #expect(soon.count > "Resets in ".count)

        limit.resetsAt = now.addingTimeInterval(86_400)
        let later = UsageMeterMapper.model(for: limit, now: now).resetText
        #expect(later.hasPrefix("Resets "))
        #expect(later.hasPrefix("Resets in ") == false)
    }

    @Test func pastResetCountsDownFromZero() {
        var limit = UsageFixture.session
        limit.resetsAt = now.addingTimeInterval(-60)

        #expect(UsageMeterMapper.model(for: limit, now: now).resetText.hasPrefix("Resets in "))
    }
}
