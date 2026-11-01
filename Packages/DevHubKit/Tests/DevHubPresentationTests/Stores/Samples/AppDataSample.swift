import DevHubDomain
import Foundation

enum AppDataSample {
    static let appSuite = AppDefaultsSuite(
        name: "com.example.app",
        plistPath: "/data/Library/Preferences/com.example.app.plist",
        entries: [AppDefault(key: "onboardingDone", kind: .bool, text: "true")]
    )

    static let groupSuite = AppDefaultsSuite(
        name: "group.com.example.app",
        plistPath: "/group/Library/Preferences/group.com.example.app.plist",
        entries: []
    )

    static let data = AppData(
        bundleID: "com.example.app",
        container: "/data",
        groups: [AppDataFile(name: "group.com.example.app", path: "/group", size: 10)],
        folders: [AppDataFile(name: "Documents", path: "/data/Documents", size: 8)],
        databases: [],
        suites: [appSuite, groupSuite]
    )
}
