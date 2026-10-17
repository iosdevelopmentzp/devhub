import Foundation

package enum BuildError: LocalizedError, Sendable {
    case noXcodeContainer(String)
    case failed(String)
    case appNotFound

    package var errorDescription: String? {
        switch self {
        case .noXcodeContainer(let path):
            "No .xcworkspace or .xcodeproj in \(path)."
        case .failed(let message):
            message
        case .appNotFound:
            "Build finished but no .app product was found for this scheme."
        }
    }
}
