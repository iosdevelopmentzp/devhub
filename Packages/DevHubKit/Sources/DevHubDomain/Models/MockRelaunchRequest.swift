import Foundation

package struct MockRelaunchRequest: Sendable {
    package var udid: String
    package var bundleID: String
    package var identity: DeviceIdentityConfig?
    package var deviceID: String?
    package var environment: String?
    package var mode: MockMode
    package var set: MockSet?

    package init(
        udid: String,
        bundleID: String,
        identity: DeviceIdentityConfig?,
        deviceID: String?,
        environment: String?,
        mode: MockMode,
        set: MockSet?
    ) {
        self.udid = udid
        self.bundleID = bundleID
        self.identity = identity
        self.deviceID = deviceID
        self.environment = environment
        self.mode = mode
        self.set = set
    }
}
