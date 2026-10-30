import Foundation

final class SourceFileLocator: @unchecked Sendable {
    private let root: URL
    private let lock = NSLock()
    private var index: [String: String]?

    private static let skippedFolders: Set<String> = ["DerivedData", "Pods", "Carthage", "node_modules", "build"]

    init(root: String) {
        self.root = URL(fileURLWithPath: (root as NSString).expandingTildeInPath)
    }

    func path(forFileName name: String) -> String? {
        lock.withLock {
            if index == nil {
                index = buildIndex()
            }
            return index?[name]
        }
    }

    private func buildIndex() -> [String: String] {
        var paths: [String: String] = [:]
        let keys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return [:] }
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: Set(keys))
            if values?.isDirectory == true {
                if Self.skippedFolders.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard url.pathExtension == "swift" || url.pathExtension == "m" || url.pathExtension == "mm" else { continue }
            paths[url.lastPathComponent] = paths[url.lastPathComponent] ?? url.path
        }
        return paths
    }
}
