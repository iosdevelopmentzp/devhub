import Foundation
import DevHubDomain

enum ContainerLocator {
    static let defaultDevicesRoot = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Developer/CoreSimulator/Devices", isDirectory: true)

    private static let metadataFile = ".com.apple.mobile_container_manager.metadata.plist"

    static func find(udid: String, bundleID: String, kind: String) -> String? {
        find(udid: udid, bundleID: bundleID, kind: kind, devicesRoot: defaultDevicesRoot)
    }

    static func find(udid: String, bundleID: String, kind: String, devicesRoot: URL) -> String? {
        let containers = devicesRoot.appendingPathComponent("\(udid)/data/Containers")
        let root = containers.appendingPathComponent(kind == "app" ? "Bundle/Application" : "Data/Application")
        let folders = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        guard let folder = folders.first(where: { identifier(of: $0) == bundleID }) else { return nil }
        guard kind == "app" else { return folder.path }
        let items = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return items.first { $0.hasSuffix(".app") }.map { folder.appendingPathComponent($0).path }
    }

    private static func identifier(of folder: URL) -> String? {
        PlistReader.dictionary(at: folder.appendingPathComponent(metadataFile))?["MCMMetadataIdentifier"] as? String
    }
}
