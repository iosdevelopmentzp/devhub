import Foundation

nonisolated struct ActionItemContext: Hashable, Sendable {
    var branch: String?
    var worktreePath: String?
    var simulatorUDID: String?
    var simulatorName: String?
    var rowID: String?

    static let none = ActionItemContext()
}

nonisolated struct ActionContext: Hashable, Sendable {
    var projectPath = ""
    var projectName = ""
    var checkoutPath = ""
    var mainPath = ""
    var branch = ""
    var baseBranch = ""
    var scheme = ""
    var configuration = ""
    var bundleID = ""
    var simulatorUDID = ""
    var simulatorName = ""
    var appPath = ""
    var worktreePath = ""
    var configDir = ""
    var rowID = ""
    var version = ""
    var inputs: [String: String] = [:]

    var variables: [String: String] {
        var values = [
            "PROJECT_PATH": projectPath,
            "PROJECT_NAME": projectName,
            "CHECKOUT_PATH": checkoutPath,
            "MAIN_PATH": mainPath,
            "BRANCH": branch,
            "BASE_BRANCH": baseBranch,
            "SCHEME": scheme,
            "CONFIGURATION": configuration,
            "BUNDLE_ID": bundleID,
            "SIMULATOR_UDID": simulatorUDID,
            "SIMULATOR_NAME": simulatorName,
            "APP_PATH": appPath,
            "WORKTREE_PATH": worktreePath,
            "CONFIG_DIR": configDir,
            "ROW_ID": rowID,
            "VERSION": version
        ]
        for (key, value) in inputs {
            values["INPUT_" + Self.environmentKey(key)] = value
        }
        return values
    }

    var environment: [String: String] {
        Dictionary(uniqueKeysWithValues: variables.map { ("DEVHUB_" + $0.key, $0.value) })
    }

    var placeholders: [String: String] {
        var values = Dictionary(uniqueKeysWithValues: variables.map { ($0.key.lowercased(), $0.value) })
        for (key, value) in inputs {
            values[key] = value
        }
        return values
    }

    private static func environmentKey(_ key: String) -> String {
        String(key.uppercased().map { $0.isLetter || $0.isNumber ? $0 : "_" })
    }
}
