import Foundation

package enum UpdateLaunchPolicy {
    package static let stoppedMessage = "The update stopped before it finished. See the log."
    package static let noMessage = "The update failed. See the log."

    package static func outcome(status: UpdateStatus?, installed: InstalledBuild, isUpdateRunning: Bool) -> UpdateLaunchOutcome {
        guard let status else { return .nothing }
        switch status.phase {
        case .done:
            guard status.commit == installed.commit else { return .clearStatus }
            return .updated(commit: installed.commit)
        case .failed:
            return .failed(message: status.message ?? noMessage)
        case .fetching, .building, .installing:
            return isUpdateRunning ? .running(status) : .stopped
        }
    }
}
