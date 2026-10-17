import Foundation
import DevHubDomain

struct XcodeProjectDetector: ProjectDetecting {

    func project(at folder: URL) -> Project {
        let path = folder.path.abbreviatingHome
        let container = try? XcodeContainer.locate(in: folder.path)
        let scheme = container?.schemeNames().first ?? container?.url.deletingPathExtension().lastPathComponent ?? folder.lastPathComponent
        let bundleID = appBundleID(in: folder) ?? ""
        return Project(
            id: path,
            name: folder.lastPathComponent,
            path: path,
            scheme: scheme,
            bundleID: bundleID,
            identity: nil
        )
    }

    func isGitRepository(_ folder: URL) -> Bool {
        FileManager.default.fileExists(atPath: folder.appendingPathComponent(".git").path)
    }

    private func appBundleID(in folder: URL) -> String? {
        let entries = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        let identifiers = entries
            .filter { $0.pathExtension == "xcodeproj" }
            .compactMap { try? String(contentsOf: $0.appendingPathComponent("project.pbxproj"), encoding: .utf8) }
            .flatMap { bundleIdentifiers(in: $0) }
        let excluded = ["Tests", "Extension", "Widget", "Intents", "Clip", "Notification"]
        return identifiers
            .filter { identifier in excluded.contains { identifier.contains($0) } == false && identifier.contains("$") == false }
            .min { $0.count < $1.count }
    }

    private func bundleIdentifiers(in pbxproj: String) -> [String] {
        pbxproj
            .components(separatedBy: "PRODUCT_BUNDLE_IDENTIFIER = ")
            .dropFirst()
            .compactMap { $0.split(separator: ";", maxSplits: 1).first }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\" ")) }
    }
}
