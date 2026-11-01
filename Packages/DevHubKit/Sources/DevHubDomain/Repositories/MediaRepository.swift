import Foundation

package protocol MediaRepository: Sendable {
    func makeGIF(from source: String, options: GIFOptions, framedFor udid: String?, onProgress: @escaping @Sendable (Double) -> Void) async throws -> String
    func compress(_ source: String, as compression: VideoCompression, framedFor udid: String?) async throws -> String
    func addFrame(to screenshot: String, udid: String) async throws
}
