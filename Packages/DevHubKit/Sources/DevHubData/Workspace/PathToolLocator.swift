import Foundation
import DevHubDomain

struct PathToolLocator: ToolLocating {
    func isInstalled(_ executable: String) -> Bool {
        path(of: executable) != nil
    }

    func path(of executable: String) -> String? {
        let inherited = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let folders = ["/opt/homebrew/bin", "/usr/local/bin", home + "/.local/bin"] + inherited.split(separator: ":").map(String.init)
        return folders.lazy.map { $0 + "/" + executable }.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
