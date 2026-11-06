import Foundation
import DevHubDomain
import DevHubUI

enum XcodeTagMapper {
    static func tag(choice: String?, configDeveloperDir: String?, systemDeveloperDir: String?, installations: [XcodeInstallation]) -> TagModel? {
        let effective = DeveloperDirPolicy.effective(choice: choice, config: configDeveloperDir)
        guard let developerDir = effective ?? systemDeveloperDir else { return nil }
        let installation = installations.first { $0.developerDir == DeveloperDirPolicy.developerDir(of: developerDir) }
        let appPath = installation?.appPath ?? DeveloperDirPolicy.appPath(ofDeveloperDir: developerDir)
        return TagModel(
            installation.map { "Xcode \($0.version)" } ?? URL(fileURLWithPath: appPath).deletingPathExtension().lastPathComponent,
            tint: .secondary,
            hint: "Builds, simctl and xed use \(name(installation, appPath: appPath)), \(source(choice: choice, configDeveloperDir: configDeveloperDir))"
        )
    }

    private static func name(_ installation: XcodeInstallation?, appPath: String) -> String {
        guard let installation else { return appPath.abbreviatingHome }
        let build = installation.build.map { " (\($0))" } ?? ""
        return "Xcode \(installation.version)\(build) at \(appPath.abbreviatingHome)"
    }

    private static func source(choice: String?, configDeveloperDir: String?) -> String {
        if choice?.trimmed.isEmpty == false { return "chosen in Settings → Projects." }
        if configDeveloperDir?.trimmed.isEmpty == false { return "from xcode.developerDir in .devhub/project.json. Change it in Settings → Projects." }
        return "the Xcode of xcode-select. Change it in Settings → Projects."
    }
}
