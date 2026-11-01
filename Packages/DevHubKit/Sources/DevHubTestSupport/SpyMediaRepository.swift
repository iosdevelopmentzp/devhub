import DevHubDomain
import Foundation

package final class SpyMediaRepository: MediaRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case makeGIF(source: String, options: GIFOptions)
        case compress(source: String, compression: VideoCompression)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _error: (any Error)? = nil
    private var _progress: [Double] = [0.5, 1]

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var error: (any Error)? {
        get { lock.withLock { _error } }
        set { lock.withLock { _error = newValue } }
    }

    package var progress: [Double] {
        get { lock.withLock { _progress } }
        set { lock.withLock { _progress = newValue } }
    }

    package func makeGIF(from source: String, options: GIFOptions, onProgress: @escaping @Sendable (Double) -> Void) async throws -> String {
        try record(.makeGIF(source: source, options: options))
        progress.forEach(onProgress)
        return MediaOutputPolicy.gifPath(for: source) { _ in false }
    }

    package func compress(_ source: String, as compression: VideoCompression) async throws -> String {
        try record(.compress(source: source, compression: compression))
        return MediaOutputPolicy.compressedPath(for: source, compression: compression) { _ in false }
    }

    private func record(_ call: Call) throws {
        try lock.withLock {
            _calls.append(call)
            if let _error { throw _error }
        }
    }
}
