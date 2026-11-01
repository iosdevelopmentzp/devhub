import Foundation

package protocol MediaRepository: Sendable {
    func makeGIF(from source: String, options: GIFOptions, onProgress: @escaping @Sendable (Double) -> Void) async throws -> String
    func compress(_ source: String, as compression: VideoCompression) async throws -> String
    func addFrame(to screenshot: String, udid: String) async throws
}
