import Foundation
import DevHubDomain

struct SpotlightXcodeInstallationRepository: XcodeInstallationRepository {
    let shell: ShellRunner

    func installations() async throws -> [XcodeInstallation] {
        let result = try await shell.run("mdfind", ["kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"], cwd: nil)
        let found = XcodeInstallationParser.appPaths(fromSpotlight: result.stdout).compactMap(Self.installation)
        return XcodeInstallationParser.sorted(found)
    }

    func selectedDeveloperDir() async throws -> String? {
        let result = try await shell.run("xcode-select", ["-p"], cwd: nil)
        let path = result.stdout.trimmed
        guard result.exitCode == 0, path.isEmpty == false else { return nil }
        return path
    }

    func installation(atDeveloperDir path: String) async throws -> XcodeInstallation? {
        Self.installation(at: DeveloperDirPolicy.appPath(ofDeveloperDir: path))
    }

    static func installation(at appPath: String) -> XcodeInstallation? {
        let plist = PlistReader.dictionary(at: URL(fileURLWithPath: appPath).appendingPathComponent("Contents/version.plist"))
        return XcodeInstallationParser.installation(appPath: appPath, versionPlist: plist)
    }
}
