import Foundation

package struct DeviceIdentityConfig: Hashable, Sendable, Codable {
    package var bundleID: String
    package var environmentSuite: String
    package var environmentKey: String
    package var environments: [String]
    package var defaultEnvironment: String
    package var deviceIDVariable: String
    package var launchArguments: [String]
    package var mockUpstreams: [String: String]? = nil
    package var keptDeviceIDVariable: String? = nil

    package init(
        bundleID: String,
        environmentSuite: String,
        environmentKey: String,
        environments: [String],
        defaultEnvironment: String,
        deviceIDVariable: String,
        launchArguments: [String],
        mockUpstreams: [String: String]? = nil,
        keptDeviceIDVariable: String? = nil
    ) {
        self.bundleID = bundleID
        self.environmentSuite = environmentSuite
        self.environmentKey = environmentKey
        self.environments = environments
        self.defaultEnvironment = defaultEnvironment
        self.deviceIDVariable = deviceIDVariable
        self.launchArguments = launchArguments
        self.mockUpstreams = mockUpstreams
        self.keptDeviceIDVariable = keptDeviceIDVariable
    }
}
