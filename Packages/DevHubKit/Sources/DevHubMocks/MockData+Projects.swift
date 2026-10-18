import Foundation
import DevHubDomain

extension MockData {
    package static let launchConfig = LaunchConfig(
        profiles: [
            LaunchProfile(id: "staging", title: "Staging", env: ["API_ENV": "staging"], storage: ProfileStorage(suite: "group.com.example.app", key: "environment"), upstream: "https://api.staging.example.com"),
            LaunchProfile(id: "production", title: "Production", env: ["API_ENV": "production"], storage: ProfileStorage(suite: "group.com.example.app", key: "environment"), production: true)
        ],
        identity: LaunchIdentityConfig(variable: "APP_DEVICE_ID", keptVariable: "APP_KEEP_DEVICE_ID", args: ["-skipOnboarding"])
    )

    package static let networkConfig = NetworkConfig(baseURLVariable: "APP_BASE_URL")

    package static let projects: [Project] = [
        Project(
            id: "example-app",
            name: "example-app",
            path: "~/Documents/Projects/example-app",
            scheme: "ExampleApp",
            bundleID: "com.example.app"
        ),
        Project(
            id: "second-app",
            name: "second-app",
            path: "~/Documents/Projects/second-app",
            scheme: "SecondApp",
            bundleID: "com.example.second"
        ),
        Project(
            id: "example-docs",
            name: "example-docs",
            path: "~/Documents/Projects/example-docs",
            scheme: "—",
            bundleID: "—"
        )
    ]
}
