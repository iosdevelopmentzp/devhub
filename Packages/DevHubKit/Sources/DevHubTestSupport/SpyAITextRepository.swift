import DevHubDomain
import Foundation

package final class SpyAITextRepository: AITextRepository, @unchecked Sendable {
    package struct Call: Hashable {
        package let prompt: String
        package let command: String
        package let cwd: String?
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _generateResult: Result<String, any Error> = .success("feat: add the gift value")

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var generateResult: Result<String, any Error> {
        get { lock.withLock { _generateResult } }
        set { lock.withLock { _generateResult = newValue } }
    }

    package func generate(prompt: String, command: String, cwd: String?) async throws -> String {
        try lock.withLock {
            _calls.append(Call(prompt: prompt, command: command, cwd: cwd))
            return try _generateResult.get()
        }
    }
}
