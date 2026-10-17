import DevHubDomain

package extension DeviceIdentityConfig {
    static let example = DeviceIdentityConfig(
        bundleID: "com.example.app",
        environmentSuite: "group.com.example.app",
        environmentKey: "selectedEnvironment",
        environments: ["qa", "dev", "prod"],
        defaultEnvironment: "qa",
        deviceIDVariable: "APP_DEVICE_ID",
        launchArguments: ["APP_DEFAULT_DEVICE_AUTH"],
        mockUpstreams: [
            "qa": "https://api-qa.example.com",
            "dev": "https://api-dev.example.com"
        ],
        keptDeviceIDVariable: "DEVHUB_DEVICE_ID"
    )
}
