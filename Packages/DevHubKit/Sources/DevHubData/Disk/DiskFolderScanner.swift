import Foundation
import DevHubDomain

enum DiskFolderScanner {
    static func items(home: URL, derivedDataRoot: URL) -> [DiskCleanupItem] {
        let xcode = home.appendingPathComponent("Library/Developer/Xcode")
        let caches = home.appendingPathComponent("Library/Caches")
        var items = derivedData(root: derivedDataRoot)
        items += children(of: [xcode.appendingPathComponent("Archives")], kind: .archives)
        items += children(of: deviceSupportFolders(in: xcode), kind: .deviceSupport)
        items += folder(caches.appendingPathComponent("org.swift.swiftpm"), kind: .swiftPMCache)
        items += folder(caches.appendingPathComponent("CocoaPods"), kind: .cocoaPodsCache)
        return items
    }

    static func derivedData(root: URL) -> [DiskCleanupItem] {
        var stale: [String] = []
        var live: [DiskCleanupItem] = []
        for folder in contents(of: root) {
            guard let workspace = workspacePath(of: folder) else { continue }
            guard FileManager.default.fileExists(atPath: workspace) else {
                stale.append(folder.path)
                continue
            }
            live.append(DiskCleanupItem(
                id: "derivedData:" + folder.path,
                kind: .derivedData,
                name: (workspace as NSString).lastPathComponent,
                detail: workspace,
                paths: [folder.path]
            ))
        }
        guard stale.isEmpty == false else { return live }
        return [DiskCleanupItem(id: DiskCleanupKind.staleDerivedData.rawValue, kind: .staleDerivedData, paths: stale, count: stale.count)] + live
    }

    private static func children(of folders: [URL], kind: DiskCleanupKind) -> [DiskCleanupItem] {
        let paths = folders.flatMap { contents(of: $0) }.map(\.path)
        guard paths.isEmpty == false else { return [] }
        return [DiskCleanupItem(id: kind.rawValue, kind: kind, paths: paths, count: paths.count)]
    }

    private static func folder(_ url: URL, kind: DiskCleanupKind) -> [DiskCleanupItem] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return [DiskCleanupItem(id: kind.rawValue, kind: kind, paths: [url.path])]
    }

    private static func deviceSupportFolders(in xcode: URL) -> [URL] {
        contents(of: xcode).filter { $0.lastPathComponent.hasSuffix(" DeviceSupport") }
    }

    private static func contents(of folder: URL) -> [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func workspacePath(of folder: URL) -> String? {
        PlistReader.dictionary(at: folder.appendingPathComponent("info.plist"))?["WorkspacePath"] as? String
    }
}
