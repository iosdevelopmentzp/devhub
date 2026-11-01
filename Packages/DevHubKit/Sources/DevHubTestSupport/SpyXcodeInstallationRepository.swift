import DevHubDomain
import Foundation

package final class SpyXcodeInstallationRepository: XcodeInstallationRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case installations
        case selectedDeveloperDir
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _installationsResult: Result<[XcodeInstallation], any Error> = .success([])
    private var _selectedResult: Result<String?, any Error> = .success(nil)

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var installationsResult: Result<[XcodeInstallation], any Error> {
        get { lock.withLock { _installationsResult } }
        set { lock.withLock { _installationsResult = newValue } }
    }

    package var selectedResult: Result<String?, any Error> {
        get { lock.withLock { _selectedResult } }
        set { lock.withLock { _selectedResult = newValue } }
    }

    package func installations() async throws -> [XcodeInstallation] {
        try lock.withLock {
            _calls.append(.installations)
            return try _installationsResult.get()
        }
    }

    package func selectedDeveloperDir() async throws -> String? {
        try lock.withLock {
            _calls.append(.selectedDeveloperDir)
            return try _selectedResult.get()
        }
    }
}
