import Foundation

package enum AIProvider: String, CaseIterable, Hashable, Sendable {
    case copilot
    case claude

    package var executable: String {
        rawValue
    }
}
