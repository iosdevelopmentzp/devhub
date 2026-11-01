import Foundation
import DevHubDomain

final class DeveloperDirState: @unchecked Sendable {
    private let lock = NSLock()
    private var path: String?

    var value: String? {
        lock.withLock { path }
    }

    func set(_ value: String?) {
        lock.withLock { path = value }
    }

    func xcodeAppName() -> String {
        value.map(DeveloperDirPolicy.appPath(ofDeveloperDir:)) ?? "Xcode"
    }
}
