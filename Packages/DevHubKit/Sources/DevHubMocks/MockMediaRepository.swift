import Foundation
import DevHubDomain

struct MockMediaRepository: MediaRepository {
    func makeGIF(from source: String, options: GIFOptions, framedFor udid: String?, onProgress: @escaping @Sendable (Double) -> Void) async throws -> String {
        for step in 1...10 {
            try await Task.sleep(for: .milliseconds(120))
            onProgress(Double(step) / 10)
        }
        return MediaOutputPolicy.gifPath(for: source, framed: udid != nil) { _ in false }
    }

    func compress(_ source: String, as compression: VideoCompression, framedFor udid: String?) async throws -> String {
        try await Task.sleep(for: .milliseconds(900))
        return MediaOutputPolicy.compressedPath(for: source, compression: compression, framed: udid != nil) { _ in false }
    }

    func addFrame(to screenshot: String, udid: String) async throws {
        try await Task.sleep(for: .milliseconds(150))
    }
}
