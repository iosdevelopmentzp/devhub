import DevHubDomain
import Foundation

package final class SpyConfigRepository: ConfigRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case load(projectPath: String)
        case changes(projectPath: String)
        case createExample(projectPath: String)
        case existingFolder(projectPath: String)
        case createStarter(projectPath: String, projectJSON: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _loadResult = ResolvedConfig.empty
    private var _createExampleResult: Result<String, TestError> = .success("/repo/.devhub")
    private var _existingFolderResult: String? = nil
    private var continuations: [AsyncStream<Void>.Continuation] = []

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var loadResult: ResolvedConfig {
        get { lock.withLock { _loadResult } }
        set { lock.withLock { _loadResult = newValue } }
    }

    package var createExampleResult: Result<String, TestError> {
        get { lock.withLock { _createExampleResult } }
        set { lock.withLock { _createExampleResult = newValue } }
    }

    package var existingFolderResult: String? {
        get { lock.withLock { _existingFolderResult } }
        set { lock.withLock { _existingFolderResult = newValue } }
    }

    package func load(projectPath: String) async -> ResolvedConfig {
        record(.load(projectPath: projectPath)) { _loadResult }
    }

    package func changes(projectPath: String) -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        record(.changes(projectPath: projectPath)) { continuations.append(continuation) }
        return stream
    }

    package func createExample(projectPath: String) async throws -> String {
        try record(.createExample(projectPath: projectPath)) { try _createExampleResult.get() }
    }

    package func createStarter(projectPath: String, projectJSON: String) async throws -> String {
        try record(.createStarter(projectPath: projectPath, projectJSON: projectJSON)) { try _createExampleResult.get() + "/project.json" }
    }

    package func existingFolder(projectPath: String) async -> String? {
        record(.existingFolder(projectPath: projectPath)) { _existingFolderResult }
    }

    package func emitChange() {
        lock.withLock { continuations }.forEach { $0.yield() }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
