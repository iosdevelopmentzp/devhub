import DevHubDomain
import Foundation

package final class SpyProjectDetector: ProjectDetecting, @unchecked Sendable {
    package enum Call: Hashable {
        case project(URL)
        case isGitRepository(URL)
    }

    private static let defaultProject: @Sendable (URL) -> Project = { folder in
        Project(id: folder.path, name: folder.lastPathComponent, path: folder.path, scheme: "", bundleID: "")
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _projectResult: @Sendable (URL) -> Project = SpyProjectDetector.defaultProject
    private var _isGitRepositoryResult: Bool = false

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var projectResult: @Sendable (URL) -> Project {
        get { lock.withLock { _projectResult } }
        set { lock.withLock { _projectResult = newValue } }
    }

    package var isGitRepositoryResult: Bool {
        get { lock.withLock { _isGitRepositoryResult } }
        set { lock.withLock { _isGitRepositoryResult = newValue } }
    }

    package func project(at folder: URL) -> Project {
        let make = record(.project(folder)) { _projectResult }
        return make(folder)
    }

    package func isGitRepository(_ folder: URL) -> Bool {
        record(.isGitRepository(folder)) { _isGitRepositoryResult }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
