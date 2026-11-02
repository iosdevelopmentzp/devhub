import Foundation
import DevHubDomain

struct MockVideoCompressionRepository: VideoCompressionRepository {
    func engineStatus() async -> VideoEngineStatus {
        .ready(version: "9.0.2", path: "/opt/homebrew/bin/ffmpeg")
    }

    func installEngine(onStep: @escaping @Sendable (String) -> Void) async throws {
        for step in MockData.homebrewSteps {
            try await Task.sleep(for: .milliseconds(300))
            onStep(step)
        }
    }

    func info(of path: String) async throws -> VideoFileInfo {
        try await Task.sleep(for: .milliseconds(150))
        return MockData.screenRecording
    }

    func compress(
        _ path: String,
        info: VideoFileInfo,
        settings: VideoCompressionSettings,
        onProgress: @escaping @Sendable (VideoCompressionProgress) -> Void
    ) async throws -> VideoCompressionResult {
        for step in 1...10 {
            try await Task.sleep(for: .milliseconds(150))
            onProgress(VideoCompressionProgress(seconds: info.duration * Double(step) / 10, speed: 4.2))
        }
        return VideoCompressionResult(path: VideoCompressionPolicy.outputPath(for: path) { _ in false }, size: info.size / 9)
    }
}
