import DevHubDomain
import DevHubTestSupport
import Foundation
import Synchronization
import Testing
@testable import DevHubData

@Suite(.tags(.integration), .serialized, .enabled(if: PathToolLocator().isInstalled("ffmpeg"), "Install ffmpeg (brew install ffmpeg) to run the ffmpeg suite"))
struct FFmpegVideoCompressionRepositoryIntegrationTests {
    private let folder: TemporaryDirectory
    private let shell = ShellRunner(recorder: SpyCommandRecorder())

    init() throws {
        folder = try TemporaryDirectory()
    }

    private var repository: FFmpegVideoCompressionRepository {
        FFmpegVideoCompressionRepository(shell: shell, tools: PathToolLocator())
    }

    @Test func theEngineIsReadyWithAVersion() async {
        let status = await repository.engineStatus()

        guard case .ready(let version, let path) = status else {
            Issue.record("Expected a ready engine, got \(status)")
            return
        }
        #expect(version.isEmpty == false)
        #expect(path.hasSuffix("/ffmpeg"))
    }

    @Test func aVideoIsReadThenCompressedNextToTheSource() async throws {
        let source = try await makeVideo(named: "Screen Recording.mov", seconds: 2)
        let progress = CallbackRecorder<VideoCompressionProgress>()

        let info = try await repository.info(of: source)
        let result = try await repository.compress(source, info: info, settings: VideoCompressionSettings(quality: .small, keepsAudio: true)) { progress.append($0) }

        #expect(info.width == 1600)
        #expect(info.height == 800)
        #expect(info.hasAudio)
        #expect(abs(info.duration - 2) < 0.1)
        #expect(result.path == folder.path("Screen Recording compressed.mp4"))
        #expect(result.size > 0)
        #expect(progress.values.last.map { abs($0.seconds - 2) < 0.1 } == true)
        let output = try await repository.info(of: result.path)
        #expect(output.width == 1280)
        #expect(output.height == 640)
        #expect(output.hasAudio)
        #expect(try hiddenFiles().isEmpty)
    }

    @Test func aFileThatIsNotAVideoCannotBeRead() async throws {
        let path = try folder.write("not a video", to: "notes.mov")

        await #expect(throws: VideoCompressionError.self) {
            try await repository.info(of: path.path)
        }
    }

    @Test func aStoppedCompressionLeavesNoFile() async throws {
        let source = try await makeVideo(named: "long.mov", seconds: 30)
        let info = try await repository.info(of: source)
        let stopper = Stopper()
        let repository = repository

        let task = Task {
            try await repository.compress(source, info: info, settings: VideoCompressionSettings(quality: .high, keepsAudio: true)) { _ in
                stopper.stop()
            }
        }
        stopper.attach(task)

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(FileManager.default.fileExists(atPath: folder.path("long compressed.mp4")) == false)
        #expect(try hiddenFiles().isEmpty)
    }

    private func makeVideo(named name: String, seconds: Int) async throws -> String {
        let path = folder.path(name)
        let ffmpeg = try #require(PathToolLocator().path(of: "ffmpeg"))
        let result = try await shell.run(ffmpeg, [
            "-hide_banner", "-nostdin", "-y", "-loglevel", "error",
            "-f", "lavfi", "-i", "testsrc2=size=1600x800:rate=30",
            "-f", "lavfi", "-i", "sine=frequency=440",
            "-t", String(seconds), "-c:v", "libx264", "-preset", "ultrafast", "-c:a", "aac", path,
        ], cwd: nil)
        try #require(result.exitCode == 0, "\(result.failureMessage)")
        return path
    }

    private func hiddenFiles() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: folder.url.path).filter { $0.hasPrefix(".") }
    }
}

private final class Stopper: Sendable {
    private let state = Mutex<(task: Task<VideoCompressionResult, any Error>?, isStopped: Bool)>((nil, false))

    func attach(_ task: Task<VideoCompressionResult, any Error>) {
        let stop = state.withLock { state in
            state.task = task
            return state.isStopped
        }
        if stop {
            task.cancel()
        }
    }

    func stop() {
        let task = state.withLock { state in
            state.isStopped = true
            return state.task
        }
        task?.cancel()
    }
}
