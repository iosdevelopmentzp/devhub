import Foundation
import DevHubDomain

enum ProfileDefaultsPlan {
    static func containerKind(for item: ProfileDefault, bundleID: String) -> String {
        item.suite.hasPrefix("group.") ? item.suite : "data"
    }

    static func writeArguments(_ item: ProfileDefault, udid: String, folder: String) -> [String] {
        let plist = (folder as NSString).appendingPathComponent("\(item.suite).plist")
        return ["spawn", udid, "defaults", "write", plist, item.key] + value(item)
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
