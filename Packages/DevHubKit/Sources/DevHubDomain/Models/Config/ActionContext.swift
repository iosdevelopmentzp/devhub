import Foundation

package struct ActionContext: Hashable, Sendable {
    package var projectPath = ""
    package var projectName = ""
    package var checkoutPath = ""
    package var mainPath = ""
    package var branch = ""
    package var baseBranch = ""
    package var scheme = ""
    package var configuration = ""
    package var bundleID = ""
    package var simulatorUDID = ""
    package var simulatorName = ""
    package var simulatorState = ""
    package var simulatorKind = ""
    package var appPath = ""
    package var worktreePath = ""
    package var configDir = ""
    package var rowID = ""
    package var version = ""
    package var pullRequestNumber = ""
    package var pullRequestURL = ""
    package var profile = ""
    package var host = ""
    package var appContainer = ""
    package var dataContainer = ""
    package var groupContainers = ""
    package var inputs: [String: String] = [:]

    package init() {}

    package var variables: [String: String] {
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
            "SIMULATOR_STATE": simulatorState,
            "SIMULATOR_KIND": simulatorKind,
            "APP_PATH": appPath,
            "WORKTREE_PATH": worktreePath,
            "CONFIG_DIR": configDir,
            "ROW_ID": rowID,
            "VERSION": version,
            "PR_NUMBER": pullRequestNumber,
            "PR_URL": pullRequestURL,
            "PROFILE": profile,
            "HOST": host,
            "APP_CONTAINER": appContainer,
            "DATA_CONTAINER": dataContainer,
            "GROUP_CONTAINERS": groupContainers
        ]
        for (key, value) in inputs {
            values["INPUT_" + Self.environmentKey(key)] = value
        }
        return values
    }

    package var environment: [String: String] {
        Dictionary(uniqueKeysWithValues: variables.map { ("DEVHUB_" + $0.key, $0.value) })
    }

    package var placeholders: [String: String] {
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
