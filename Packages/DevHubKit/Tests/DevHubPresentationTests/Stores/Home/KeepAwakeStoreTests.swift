import DevHubDomain
import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct KeepAwakeStoreTests {
    private let harness = StoreHarness()

    @Test func toggleOnPreventsSleep() {
        harness.keepAwake.toggle()

        #expect(harness.keepAwake.isActive)
        #expect(harness.spies.sleep.calls == [.preventSleep(reason: "DevHub: Keep Mac awake")])
        #expect(harness.lastActivity?.title == "Keep Mac awake: on")
    }

    @Test func toggleOffAllowsSleep() {
        harness.keepAwake.toggle()

        harness.keepAwake.toggle()

        #expect(harness.keepAwake.isActive == false)
        #expect(harness.spies.sleep.calls.last == .allowSleep)
        #expect(harness.lastActivity?.title == "Keep Mac awake: off")
    }

    @Test func failureStaysOffAndIsLogged() {
        harness.spies.sleep.preventError = TestError.scripted("denied")

        harness.keepAwake.toggle()

        #expect(harness.keepAwake.isActive == false)
        #expect(harness.lastActivity?.title == "Could not keep the Mac awake")
        #expect(harness.lastActivity?.outcome == .failure)
    }
}
