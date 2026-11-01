import Foundation
import DevHubDomain

extension MockData {
    package static let appDataContainer = "/Users/alex/Library/Developer/CoreSimulator/Devices/3F2A9C1E-7B4D-4E8A-9C21-5D6E7F8A9B0C/data/Containers/Data/Application/8C1D2E3F-4A5B-4C6D-8E7F-9A0B1C2D3E4F"
    package static let appGroupContainer = "/Users/alex/Library/Developer/CoreSimulator/Devices/3F2A9C1E-7B4D-4E8A-9C21-5D6E7F8A9B0C/data/Containers/Shared/AppGroup/1A2B3C4D-5E6F-4A7B-8C9D-0E1F2A3B4C5D"

    package static let appData = AppData(
        bundleID: "com.example.app",
        container: appDataContainer,
        groups: [
            AppDataFile(name: "group.com.example.app", path: appGroupContainer, size: 2_400_000),
        ],
        folders: [
            AppDataFile(name: "Documents", path: appDataContainer + "/Documents", size: 1_250_000),
            AppDataFile(name: "Library/Application Support", path: appDataContainer + "/Library/Application Support", size: 3_400_000),
            AppDataFile(name: "Library/Caches", path: appDataContainer + "/Library/Caches", size: 12_800_000),
            AppDataFile(name: "Library/Preferences", path: appDataContainer + "/Library/Preferences", size: 4_100),
            AppDataFile(name: "tmp", path: appDataContainer + "/tmp", size: 0),
        ],
        databases: [
            AppDataFile(name: "Library/Application Support/Model.sqlite", path: appDataContainer + "/Library/Application Support/Model.sqlite", size: 1_100_000),
            AppDataFile(name: "group.com.example.app/Library/Shared.sqlite", path: appGroupContainer + "/Library/Shared.sqlite", size: 420_000),
        ],
        suites: [
            AppDefaultsSuite(
                name: "com.example.app",
                plistPath: appDataContainer + "/Library/Preferences/com.example.app.plist",
                entries: [
                    AppDefault(key: "apiEnvironment", kind: .string, text: "staging"),
                    AppDefault(key: "featureFlags", kind: .dictionary, text: "{newCheckout: true, search: false}"),
                    AppDefault(key: "lastSyncDate", kind: .date, text: "2026-10-30T09:41:00Z"),
                    AppDefault(key: "launchCount", kind: .integer, text: "14"),
                    AppDefault(key: "onboardingDone", kind: .bool, text: "true"),
                    AppDefault(key: "recentSearches", kind: .array, text: "[\"shoes\", \"jackets\"]"),
                ]
            ),
            AppDefaultsSuite(
                name: "group.com.example.app",
                plistPath: appGroupContainer + "/Library/Preferences/group.com.example.app.plist",
                entries: [
                    AppDefault(key: "sharedToken", kind: .data, text: "64 bytes"),
                    AppDefault(key: "widgetTheme", kind: .string, text: "dark"),
                ]
            ),
        ]
    )
}
