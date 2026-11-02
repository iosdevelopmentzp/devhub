import DevHubDomain
import Foundation

package final class SpyVideoCompressionRepository: VideoCompressionRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case engineStatus
        case installEngine
        case info(path: String)
        case compress(path: String, settings: VideoCompressionSettings)
    }

    package static let sampleInfo = VideoFileInfo(duration: 40, width: 3456, height: 2234, frameRate: 60, codec: "h264", hasAudio: true, size: 80_000_000)

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _engineStatusResult: VideoEngineStatus = .ready(version: "9.0.2", path: "/opt/homebrew/bin/ffmpeg")
    private var _engineStatusAfterInstall: VideoEngineStatus? = nil
    private var _installSteps: [String] = ["Pouring ffmpeg"]
    private var _installError: (any Error)? = nil
    private var _infoResult: Result<VideoFileInfo, any Error> = .success(sampleInfo)
    private var _progress: [VideoCompressionProgress] = [VideoCompressionProgress(seconds: 20, speed: 4), VideoCompressionProgress(seconds: 40, speed: 4)]
    private var _compressedSize: Int64 = 8_000_000
    private var _compressError: (any Error)? = nil
    private var _compressHold: Duration = .zero

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var engineStatusResult: VideoEngineStatus {
        get { lock.withLock { _engineStatusResult } }
        set { lock.withLock { _engineStatusResult = newValue } }
    }

    package var engineStatusAfterInstall: VideoEngineStatus? {
        get { lock.withLock { _engineStatusAfterInstall } }
        set { lock.withLock { _engineStatusAfterInstall = newValue } }
    }

    package var installSteps: [String] {
        get { lock.withLock { _installSteps } }
        set { lock.withLock { _installSteps = newValue } }
    }

    package var installError: (any Error)? {
        get { lock.withLock { _installError } }
        set { lock.withLock { _installError = newValue } }
    }

    package var infoResult: Result<VideoFileInfo, any Error> {
        get { lock.withLock { _infoResult } }
        set { lock.withLock { _infoResult = newValue } }
    }

    package var progress: [VideoCompressionProgress] {
        get { lock.withLock { _progress } }
        set { lock.withLock { _progress = newValue } }
    }

    package var compressedSize: Int64 {
        get { lock.withLock { _compressedSize } }
        set { lock.withLock { _compressedSize = newValue } }
    }

    package var compressError: (any Error)? {
        get { lock.withLock { _compressError } }
        set { lock.withLock { _compressError = newValue } }
    }

    package var compressHold: Duration {
        get { lock.withLock { _compressHold } }
        set { lock.withLock { _compressHold = newValue } }
    }

    package func engineStatus() async -> VideoEngineStatus {
        lock.withLock {
            _calls.append(.engineStatus)
            return _engineStatusResult
        }
    }

    package func installEngine(onStep: @escaping @Sendable (String) -> Void) async throws {
        lock.withLock { _calls.append(.installEngine) }
        installSteps.forEach(onStep)
        if let installError {
            throw installError
        }
        if let engineStatusAfterInstall {
            engineStatusResult = engineStatusAfterInstall
        }
    }

    package func info(of path: String) async throws -> VideoFileInfo {
        lock.withLock { _calls.append(.info(path: path)) }
        return try infoResult.get()
    }

    package func compress(
        _ path: String,
        info: VideoFileInfo,
        settings: VideoCompressionSettings,
        onProgress: @escaping @Sendable (VideoCompressionProgress) -> Void
    ) async throws -> VideoCompressionResult {
        lock.withLock { _calls.append(.compress(path: path, settings: settings)) }
        if compressHold > .zero {
            try await Task.sleep(for: compressHold)
        }
        progress.forEach(onProgress)
        if let compressError {
            throw compressError
        }
        return VideoCompressionResult(path: VideoCompressionPolicy.outputPath(for: path) { _ in false }, size: compressedSize)
    }
}
