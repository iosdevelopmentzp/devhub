import DevHubDomain
import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct DoctorStoreTests {
    private let harness = StoreHarness()

    @Test func checkReadsEveryToolAndTheAccessibilityState() async {
        harness.spies.attacher.isTrusted = false

        await harness.doctor.check()

        #expect(harness.doctor.statuses.map(\.tool.name) == DoctorPolicy.tools.map(\.name))
        #expect(harness.doctor.statuses.allSatisfy { $0.isInstalled == false })
        #expect(harness.doctor.isAccessibilityTrusted == false)
        #expect(harness.doctor.isChecking == false)
    }

    @Test func requestAccessibilityAsksTheSystem() {
        harness.doctor.requestAccessibility()

        #expect(harness.spies.attacher.calls.contains(.requestTrust))
    }
}
