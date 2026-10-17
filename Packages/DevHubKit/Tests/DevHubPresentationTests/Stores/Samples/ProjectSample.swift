import DevHubDomain
import DevHubTestSupport

enum ProjectSample {
    static let path = "/tmp/DevHubTests/App"

    static let app = Project(
        id: "app",
        name: "App",
        path: path,
        scheme: "App",
        bundleID: "com.example.app",
        identity: nil
    )

    static let identified = Project(
        id: "identified",
        name: "Identified",
        path: "/tmp/DevHubTests/Identified",
        scheme: "Identified",
        bundleID: "com.example.identified",
        identity: .example
    )

    static let other = Project(
        id: "other",
        name: "Other",
        path: "/tmp/DevHubTests/Other",
        scheme: "Other",
        bundleID: "com.example.other",
        identity: nil
    )
}
