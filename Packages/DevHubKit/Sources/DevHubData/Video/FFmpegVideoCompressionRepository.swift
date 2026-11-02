import Foundation
import DevHubDomain

struct FFmpegVideoCompressionRepository: VideoCompressionRepository {
    let shell: ShellRunner
    let tools: any ToolLocating

    func engineStatus() async -> VideoEngineStatus {
        guard let ffmpeg = tools.path(of: "ffmpeg") else {
            return .missing(homebrewPath: tools.path(of: "brew"))
        }
        let versionOutput = (try? await shell.run(ffmpeg, FFmpegArguments.version, cwd: nil))?.stdout ?? ""
        let version = FFmpegVersionParser.version(from: versionOutput) ?? "unknown version"
        guard tools.path(of: "ffprobe") != nil else {
            return .incomplete(version: version, path: ffmpeg, missing: "ffprobe")
        }
        let encoders = (try? await shell.run(ffmpeg, FFmpegArguments.encoders, cwd: nil))?.stdout ?? ""
        guard FFmpegArguments.hasEncoder("libx264", in: encoders) else {
            return .incomplete(version: version, path: ffmpeg, missing: "libx264")
        }
        return .ready(version: version, path: ffmpeg)
    }

    func installEngine(onStep: @escaping @Sendable (String) -> Void) async throws {
        guard let brew = tools.path(of: "brew") else {
            throw VideoCompressionError.homebrewMissing
        }
        let lines = LineCollector()
        let exitCode = try await shell.stream(brew, FFmpegArguments.install, cwd: nil, environment: FFmpegArguments.installEnvironment) { line in
            lines.append(line)
            if let step = HomebrewOutputParser.step(from: line) {
                onStep(step)
            }
        }
        try Task.checkCancellation()
        guard exitCode == 0 else {
            let output = lines.text.components(separatedBy: "\n")
            throw VideoCompressionError.installFailed(HomebrewOutputParser.failure(from: output, exitCode: exitCode))
        }
    }

    func info(of path: String) async throws -> VideoFileInfo {
        let name = (path as NSString).lastPathComponent
        guard let ffprobe = tools.path(of: "ffprobe") else {
            throw VideoCompressionError.engineMissing
        }
        let result = try await shell.run(ffprobe, FFmpegArguments.info(path), cwd: nil)
        guard result.exitCode == 0 else {
            let reason = result.failureMessage.components(separatedBy: "\n").last.map(FFmpegOutputParser.message) ?? result.failureMessage
            throw VideoCompressionError.unreadable(name, reason: reason)
        }
        guard let info = FFprobeInfoParser.parse(result.stdout) else {
            throw VideoCompressionError.unreadable(name, reason: "the file has no video stream.")
        }
        return info
    }

    func compress(
        _ path: String,
        info: VideoFileInfo,
        settings: VideoCompressionSettings,
        onProgress: @escaping @Sendable (VideoCompressionProgress) -> Void
    ) async throws -> VideoCompressionResult {
        guard let ffmpeg = tools.path(of: "ffmpeg") else {
            throw VideoCompressionError.engineMissing
        }
        let files = FileManager.default
        let output = VideoCompressionPolicy.outputPath(for: path) { files.fileExists(atPath: $0) }
        let partial = VideoCompressionPolicy.partialPath(for: output, token: String(UUID().uuidString.prefix(8)))
        let parser = FFmpegOutputParser()
        let exitCode: Int32
        do {
            exitCode = try await shell.stream(ffmpeg, FFmpegArguments.compress(path, to: partial, info: info, settings: settings), cwd: nil) { line in
                if let progress = parser.read(line) {
                    onProgress(progress)
                }
            }
        } catch {
            try? files.removeItem(atPath: partial)
            throw error
        }
        guard Task.isCancelled == false else {
            try? files.removeItem(atPath: partial)
            throw CancellationError()
        }
        guard exitCode == 0 else {
            try? files.removeItem(atPath: partial)
            throw VideoCompressionError.command(parser.failure(exitCode: exitCode))
        }
        return try save(partial, for: path)
    }

    private func save(_ partial: String, for source: String) throws -> VideoCompressionResult {
        let files = FileManager.default
        let destination = VideoCompressionPolicy.outputPath(for: source) { files.fileExists(atPath: $0) }
        do {
            try files.moveItem(atPath: partial, toPath: destination)
        } catch {
            try? files.removeItem(atPath: partial)
            throw VideoCompressionError.command("Cannot save \((destination as NSString).lastPathComponent): \(error.localizedDescription)")
        }
        let size = (try? files.attributesOfItem(atPath: destination)[.size] as? NSNumber)?.int64Value ?? 0
        return VideoCompressionResult(path: destination, size: size)
    }
}
