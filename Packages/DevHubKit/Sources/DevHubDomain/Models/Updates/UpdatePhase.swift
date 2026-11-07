import Foundation

package enum UpdatePhase: String, Codable, Sendable, CaseIterable {
    case fetching
    case building
    case installing
    case done
    case failed

    package var title: String {
        switch self {
        case .fetching: "Getting changes"
        case .building: "Building"
        case .installing: "Installing"
        case .done: "Done"
        case .failed: "Failed"
        }
    }

    package var isRunning: Bool {
        switch self {
        case .fetching, .building, .installing: true
        case .done, .failed: false
        }
    }
}
