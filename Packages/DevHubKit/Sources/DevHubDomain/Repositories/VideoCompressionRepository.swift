import Foundation

package protocol VideoCompressionRepository: Sendable {
    func engineStatus() async -> VideoEngineStatus
    func installEngine(onStep: @escaping @Sendable (String) -> Void) async throws
    func info(of path: String) async throws -> VideoFileInfo
    func compress(_ path: String, info: VideoFileInfo, settings: VideoCompressionSettings, onProgress: @escaping @Sendable (VideoCompressionProgress) -> Void) async throws -> VideoCompressionResult
}
