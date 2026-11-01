import DevHubDomain
import Foundation

package final class SpyToolEnvironmentRepository: ToolEnvironmentRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case setDeveloperDir(String?)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package func setDeveloperDir(_ path: String?) async {
        lock.withLock { _calls.append(.setDeveloperDir(path)) }
    }
}
