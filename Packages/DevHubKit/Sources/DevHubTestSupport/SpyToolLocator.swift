import DevHubDomain
import Foundation

package final class SpyToolLocator: ToolLocating, @unchecked Sendable {
    private let lock = NSLock()
    private var _installedTools: Set<String> = []

    package init() {}

    package var installedTools: Set<String> {
        get { lock.withLock { _installedTools } }
        set { lock.withLock { _installedTools = newValue } }
    }

    package func isInstalled(_ executable: String) -> Bool {
        lock.withLock { _installedTools.contains(executable) }
    }
}
