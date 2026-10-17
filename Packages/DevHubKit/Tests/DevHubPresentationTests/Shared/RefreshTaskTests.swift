import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct RefreshTaskTests {
    @Test func secondRunCancelsTheFirst() async throws {
        let refresh = RefreshTask()
        let state = Probe()
        let first = Task {
            await refresh.run {
                state.firstStarted = true
                while Task.isCancelled == false {
                    await Task.yield()
                }
                state.firstSawCancellation = true
            }
        }
        try await waitUntil { state.firstStarted }

        await refresh.run { state.value = "second" }
        await first.value

        #expect(state.firstSawCancellation)
        #expect(state.value == "second")
    }

    @Test func cancelledRunDoesNotWriteLater() async throws {
        let refresh = RefreshTask()
        let state = Probe()
        let first = Task {
            await refresh.run {
                state.firstStarted = true
                while Task.isCancelled == false {
                    await Task.yield()
                }
                try Task.checkCancellation()
                state.value = "first"
            }
        }
        try await waitUntil { state.firstStarted }

        await refresh.run { state.value = "second" }
        await first.value

        #expect(state.value == "second")
    }

    @Test func runAwaitsTheWork() async {
        let refresh = RefreshTask()
        let state = Probe()

        await refresh.run {
            await Task.yield()
            state.value = "done"
        }

        #expect(state.value == "done")
    }

    @Test func thrownErrorIsSwallowed() async {
        let refresh = RefreshTask()
        let state = Probe()

        await refresh.run { throw TestError.scripted("boom") }
        await refresh.run { state.value = "after" }

        #expect(state.value == "after")
    }
}

private final class Probe {
    var firstStarted = false
    var firstSawCancellation = false
    var value = ""
}
