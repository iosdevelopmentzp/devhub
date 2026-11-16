import Foundation

package enum GitHiddenFilePolicy {
    package static func relativePath(of file: String, in checkout: String) -> String? {
        let root = standardized(checkout)
        let path = standardized(file)
        let prefix = root.hasSuffix("/") ? root : root + "/"
        guard path.hasPrefix(prefix), path.count > prefix.count else { return nil }
        return String(path.dropFirst(prefix.count))
    }

    private static func standardized(_ path: String) -> String {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.resolvingSymlinksInPath().path
    }
}
