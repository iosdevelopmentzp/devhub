import Foundation
import DevHubDomain
import DevHubUI

enum XcodeOptionMapper {
    static let hint = "The Xcode that xcodebuild, simctl and xed use for this project (DEVELOPER_DIR). Default: xcode.developerDir in .devhub/project.json, else the Xcode of xcode-select."

    static func options(installations: [XcodeInstallation], systemDeveloperDir: String?, configDeveloperDir: String?, choice: String?) -> [XcodeOptionModel] {
        let fallback = configDeveloperDir.map(DeveloperDirPolicy.developerDir)
        let defaultTitle = fallback.map { "project.json · \(name(of: $0, in: installations))" }
            ?? "Default · \(systemDeveloperDir.map { name(of: $0, in: installations) } ?? "xcode-select")"
        var options = [XcodeOptionModel(id: "", title: defaultTitle)]
        options += installations.map { XcodeOptionModel(id: $0.developerDir, title: title(of: $0)) }
        if let choice, choice.isEmpty == false, options.contains(where: { $0.id == choice }) == false {
            options.append(XcodeOptionModel(id: choice, title: "Not found · \(choice.abbreviatingHome)"))
        }
        return options
    }

    static func summary(effective: String?, systemDeveloperDir: String?, installations: [XcodeInstallation]) -> String {
        guard let effective else {
            return "Builds use the Xcode of xcode-select: \(systemDeveloperDir.map { name(of: $0, in: installations) } ?? "unknown")"
        }
        return "Builds use \(name(of: effective, in: installations)) (DEVELOPER_DIR)"
    }

    static func title(of installation: XcodeInstallation) -> String {
        "Xcode \(installation.version) · \(URL(fileURLWithPath: installation.appPath).lastPathComponent)"
    }

    private static func name(of developerDir: String, in installations: [XcodeInstallation]) -> String {
        guard let installation = installations.first(where: { $0.developerDir == DeveloperDirPolicy.developerDir(of: developerDir) }) else {
            return DeveloperDirPolicy.appPath(ofDeveloperDir: developerDir).abbreviatingHome
        }
        return title(of: installation)
    }
}
