import DevHubDomain
import DevHubTestSupport

enum ProjectFixture {
    static let exampleApp = Project(
        id: "example-app",
        name: "ExampleApp",
        path: "/Users/dev/Projects/ExampleApp",
        scheme: "ExampleApp",
        bundleID: "com.example.app",
        identity: .example
    )

    static let devHub = Project(
        id: "devhub",
        name: "DevHub",
        path: "/Users/dev/Projects/DevHub",
        scheme: "DevHub",
        bundleID: "com.example.devhub",
        identity: nil
    )
}
