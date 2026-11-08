import Foundation
import DevHubDomain

enum ProfileDefaultsPlan {
    static func containerKind(suite: String, appGroups: [String]) -> String {
        appGroups.contains(suite) ? suite : "data"
    }

    static func mayUseAppGroup(_ suites: [String]) -> Bool {
        suites.contains { $0.hasPrefix("group.") }
    }

    static func writeArguments(_ item: ProfileDefault, udid: String, folder: String) -> [String] {
        let plist = (folder as NSString).appendingPathComponent("\(item.suite).plist")
        return ["spawn", udid, "defaults", "write", plist, item.key] + value(item)
    }

    static func localWriteArguments(_ item: ProfileDefault, folder: String) -> [String] {
        ["write", (folder as NSString).appendingPathComponent(item.suite), item.key] + value(item)
    }

    static func preferencesPath(suite: String) -> String {
        "Library/Preferences/\(suite).plist"
    }

    private static func value(_ item: ProfileDefault) -> [String] {
        switch item.type ?? "string" {
        case "bool": ["-bool", ["true", "1", "yes"].contains(item.value.lowercased()) ? "true" : "false"]
        case "int", "integer": ["-integer", item.value]
        case "float", "double": ["-float", item.value]
        default: ["-string", item.value]
        }
    }
}
