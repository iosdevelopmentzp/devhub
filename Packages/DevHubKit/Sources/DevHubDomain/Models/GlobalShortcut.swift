import Foundation

package enum GlobalShortcut: String, Codable, CaseIterable, Hashable, Sendable {
    case off
    case optionCommandD
    case controlOptionSpace
    case controlOptionD

    package var title: String {
        switch self {
        case .off: "Off"
        case .optionCommandD: "⌥⌘D"
        case .controlOptionSpace: "⌃⌥Space"
        case .controlOptionD: "⌃⌥D"
        }
    }
}
