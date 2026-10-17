import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct WaitUntilTests {
    @Test func waitsForFlagSetByTask() async throws {
        let flag = Flag()
        Task {
            await Task.yield()
            flag.isSet = true
        }

        try await waitUntil { flag.isSet }

        #expect(flag.isSet)
    }

    @Test func throwsWhenConditionNeverHolds() async {
        await #expect(throws: TestError.timedOut) {
            try await waitUntil(timeout: .milliseconds(50)) { false }
        }
    }
}

private final class Flag {
    var isSet = false
}
