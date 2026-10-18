import Foundation
import Testing
@testable import DevHubDomain

@Suite struct LaunchIdentityConfigTests {
    private let uuid = UUID(uuidString: "3F9A1C2E-0000-4000-8000-000000000000")!

    @Test func defaultsApplyWhenKeysAreMissing() {
        let config = LaunchIdentityConfig(variable: "APP_DEVICE_ID")

        #expect(config.marker == "APP_DEVICE_ID")
        #expect(config.cleansOnChange)
        #expect(config.newIdentity(uuid: uuid) == "devhub-3f9a1c2e")
    }

    @Test func configuredValuesWin() {
        let config = LaunchIdentityConfig(variable: "APP_DEVICE_ID", idPrefix: "qa-", cleanInstallOnChange: false, hookMarker: "DEBUG_HOOKS")

        #expect(config.marker == "DEBUG_HOOKS")
        #expect(config.cleansOnChange == false)
        #expect(config.newIdentity(uuid: uuid) == "qa-3f9a1c2e")
    }
}
