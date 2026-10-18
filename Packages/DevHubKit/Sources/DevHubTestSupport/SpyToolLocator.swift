import DevHubDomain
import Foundation

package final class SpyToolLocator: ToolLocating, @unchecked Sendable {
    private let lock = NSLock()
    private var _installedTools: Set<String> = []
    private var _existingFiles: Set<String> = []

    package init() {}

    package var installedTools: Set<String> {
        get { lock.withLock { _installedTools } }
        set { lock.withLock { _installedTools = newValue } }
    }

    package var existingFiles: Set<String> {
        get { lock.withLock { _existingFiles } }
        set { lock.withLock { _existingFiles = newValue } }
    }

    package func isInstalled(_ executable: String) -> Bool {
        lock.withLock { _installedTools.contains(executable) }
    }

    package func path(of executable: String) -> String? {
        lock.withLock { _installedTools.contains(executable) ? "/usr/local/bin/" + executable : nil }
    }

    package func fileExists(atPath path: String) -> Bool {
        lock.withLock { _existingFiles.contains(path) }
    }
}
