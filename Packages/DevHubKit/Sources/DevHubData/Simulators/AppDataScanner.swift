import Foundation
import DevHubDomain

enum AppDataScanner {
    static let folderPaths = ["Documents", "Library/Application Support", "Library/Caches", "Library/Preferences", "tmp"]
    static let resetPaths = ["Documents", "Library", "tmp"]
    static let databaseExtensions: Set<String> = ["sqlite", "sqlite3", "db", "store", "realm"]
    static let databaseLimit = 40
    static let metadataFile = ".com.apple.mobile_container_manager.metadata.plist"

    static func folders(in container: String) -> [AppDataFile] {
        folderPaths.compactMap { relative in
            let path = (container as NSString).appendingPathComponent(relative)
            guard isFolder(path) else { return nil }
            return AppDataFile(name: relative, path: path, size: size(of: path))
        }
    }

    static func sized(_ groups: [AppDataFile]) -> [AppDataFile] {
        groups.map { AppDataFile(name: $0.name, path: $0.path, size: size(of: $0.path)) }
    }

    static func databases(in roots: [(prefix: String, path: String)]) -> [AppDataFile] {
        let found = roots.flatMap { root in
            files(in: root.path)
                .filter { databaseExtensions.contains($0.url.pathExtension.lowercased()) }
                .map { AppDataFile(name: root.prefix + relativePath($0.url.path, in: root.path), path: $0.url.path, size: $0.size) }
        }
        return Array(found.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }.prefix(databaseLimit))
    }

    static func size(of path: String) -> Int64 {
        files(in: path).reduce(0) { $0 + $1.size }
    }

    static func clearContainer(_ container: String) throws {
        for relative in resetPaths {
            try clear((container as NSString).appendingPathComponent(relative), keeping: [])
        }
    }

    static func clearGroup(_ path: String) throws {
        try clear(path, keeping: [metadataFile])
    }

    private static func clear(_ folder: String, keeping: Set<String>) throws {
        guard isFolder(folder) else { return }
        for name in try FileManager.default.contentsOfDirectory(atPath: folder) where keeping.contains(name) == false {
            try FileManager.default.removeItem(atPath: (folder as NSString).appendingPathComponent(name))
        }
    }

    private static func relativePath(_ path: String, in root: String) -> String {
        let resolvedRoot = URL(fileURLWithPath: root).resolvingSymlinksInPath().path
        let resolvedPath = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
        guard resolvedPath.hasPrefix(resolvedRoot + "/") else { return (path as NSString).lastPathComponent }
        return String(resolvedPath.dropFirst(resolvedRoot.count + 1))
    }

    private static func isFolder(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private static func files(in path: String) -> [(url: URL, size: Int64)] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: keys) else { return [] }
        return enumerator.compactMap { item in
            guard let url = item as? URL,
                  let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else { return nil }
            return (url, Int64(values.fileSize ?? 0))
        }
    }
}
