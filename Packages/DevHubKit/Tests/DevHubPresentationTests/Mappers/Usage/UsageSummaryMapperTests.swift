import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct UsageSummaryMapperTests {
    @Test func summaryHasMetersPlanAndUpdateTime() {
        let model = UsageSummaryMapper.model(for: UsageFixture.usage, now: UsageFixture.now)

        #expect(model.meters == [
            UsageMeterMapper.model(for: UsageFixture.session, now: UsageFixture.now),
            UsageMeterMapper.model(for: UsageFixture.week, now: UsageFixture.now)
        ])
        #expect(model.planTag == TagModel("Max", tint: .indigo, systemImage: "person.2"))
        #expect(model.updatedText.hasPrefix("Updated "))
    }
}
