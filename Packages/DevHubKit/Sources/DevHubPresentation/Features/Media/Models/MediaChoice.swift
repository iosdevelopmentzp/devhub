import Foundation
import DevHubDomain

enum MediaChoice: CaseIterable, Identifiable, Hashable {
    case smallGIF
    case mediumGIF
    case largeGIF
    case mp4At720p
    case hevcAt1080p

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .smallGIF: "GIF, 320 px, 10 fps"
        case .mediumGIF: "GIF, 480 px, 15 fps"
        case .largeGIF: "GIF, 640 px, 15 fps"
        case .mp4At720p: "MP4, 720p (H.264)"
        case .hevcAt1080p: "MP4, 1080p (HEVC, smaller)"
        }
    }

    var gifOptions: GIFOptions? {
        switch self {
        case .smallGIF: GIFOptions(width: 320, framesPerSecond: 10)
        case .mediumGIF: GIFOptions(width: 480, framesPerSecond: 15)
        case .largeGIF: GIFOptions(width: 640, framesPerSecond: 15)
        case .mp4At720p, .hevcAt1080p: nil
        }
    }

    var compression: VideoCompression? {
        switch self {
        case .mp4At720p: .h264At720p
        case .hevcAt1080p: .hevcAt1080p
        case .smallGIF, .mediumGIF, .largeGIF: nil
        }
    }
}
