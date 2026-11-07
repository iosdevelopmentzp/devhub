import Foundation

enum CIDownloadState: Equatable {
    case downloading
    case done(folder: String)
    case failure(String)
}
