import Foundation

enum VideoInstallState: Equatable {
    case idle
    case running(step: String)
    case failed(String)

    var isRunning: Bool {
        guard case .running = self else { return false }
        return true
    }
}
