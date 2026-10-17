import Foundation
import DevHubDomain

extension MockData {
    package static let identityConfig = DeviceIdentityConfig(
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

    package static let projects: [Project] = [
        Project(
            id: "example-app",
            name: "example-app",
            path: "~/Documents/Projects/example-app",
            scheme: "ExampleApp",
            bundleID: "com.example.app",
            identity: identityConfig
        ),
        Project(
            id: "second-app",
            name: "second-app",
            path: "~/Documents/Projects/second-app",
            scheme: "SecondApp",
            bundleID: "com.example.second",
            identity: nil
        ),
        Project(
            id: "example-docs",
            name: "example-docs",
            path: "~/Documents/Projects/example-docs",
            scheme: "—",
            bundleID: "—",
            identity: nil
        )
    ]
}
