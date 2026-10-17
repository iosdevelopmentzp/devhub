import Foundation

package struct BuildIdentity: Sendable {
    package var config: DeviceIdentityConfig
    package var deviceID: String?
    package var environment: String?

    package init(config: DeviceIdentityConfig, deviceID: String?, environment: String?) {
        self.config = config
        self.deviceID = deviceID
        self.environment = environment
    }
}
