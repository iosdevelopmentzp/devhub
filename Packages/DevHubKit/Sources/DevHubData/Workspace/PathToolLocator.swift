import Foundation
import DevHubDomain

struct PathToolLocator: ToolLocating {
    func isInstalled(_ executable: String) -> Bool {
        let inherited = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let folders = ["/opt/homebrew/bin", "/usr/local/bin"] + inherited.split(separator: ":").map(String.init)
        return folders.contains { FileManager.default.isExecutableFile(atPath: $0 + "/" + executable) }
    }
}
