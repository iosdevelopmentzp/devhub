import Foundation

package enum DiskCleanupPolicy {
    package static func roots(home: URL, derivedDataRoot: URL) -> [String] {
        [
            derivedDataRoot.path,
            home.appendingPathComponent("Library/Developer/Xcode").path,
            home.appendingPathComponent("Library/Caches").path,
        ]
    }

    package static func isRemovable(_ path: String, roots: [String]) -> Bool {
        guard path.hasPrefix("/"), path.split(separator: "/").contains("..") == false else { return false }
        let target = standardized(path)
        return roots.contains { root in
            let parent = standardized(root)
            return parent.count > 1 && target.hasPrefix(parent + "/")
        }
    }

    package static func totalSize(of items: [DiskCleanupItem], sizes: [DiskCleanupItem.ID: Int64]) -> Int64 {
        items.reduce(0) { total, item in total + (sizes[item.id] ?? item.size ?? 0) }
    }

    private static func standardized(_ path: String) -> String {
        let value = URL(fileURLWithPath: path).standardizedFileURL.path
        return value.count > 1 && value.hasSuffix("/") ? String(value.dropLast()) : value
    }
}
