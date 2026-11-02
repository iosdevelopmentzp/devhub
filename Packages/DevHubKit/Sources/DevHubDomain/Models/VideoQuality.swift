import Foundation

package enum VideoQuality: String, CaseIterable, Hashable, Codable, Sendable {
    case high
    case balanced
    case small

    package var maximumLongSide: Int? {
        switch self {
        case .high: nil
        case .balanced: 1920
        case .small: 1280
        }
    }

    package var maximumFrameRate: Int {
        switch self {
        case .high: 60
        case .balanced, .small: 30
        }
    }
}
