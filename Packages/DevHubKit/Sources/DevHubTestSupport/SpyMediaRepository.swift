import DevHubDomain
import Foundation

package final class SpyMediaRepository: MediaRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case makeGIF(source: String, options: GIFOptions, framedFor: String?)
        case compress(source: String, compression: VideoCompression, framedFor: String?)
        case addFrame(screenshot: String, udid: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _error: (any Error)? = nil
    private var _progress: [Double] = [0.5, 1]
    private var _frameError: (any Error)? = nil

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

    package var frameError: (any Error)? {
        get { lock.withLock { _frameError } }
        set { lock.withLock { _frameError = newValue } }
    }

    package func makeGIF(from source: String, options: GIFOptions, framedFor udid: String?, onProgress: @escaping @Sendable (Double) -> Void) async throws -> String {
        try record(.makeGIF(source: source, options: options, framedFor: udid))
        progress.forEach(onProgress)
        return MediaOutputPolicy.gifPath(for: source, framed: udid != nil) { _ in false }
    }

    package func compress(_ source: String, as compression: VideoCompression, framedFor udid: String?) async throws -> String {
        try record(.compress(source: source, compression: compression, framedFor: udid))
        return MediaOutputPolicy.compressedPath(for: source, compression: compression, framed: udid != nil) { _ in false }
    }

    package func addFrame(to screenshot: String, udid: String) async throws {
        try record(.addFrame(screenshot: screenshot, udid: udid))
        if let frameError {
            throw frameError
        }
    }

    private func record(_ call: Call) throws {
        try lock.withLock {
            _calls.append(call)
            if let _error { throw _error }
        }
    }
}
