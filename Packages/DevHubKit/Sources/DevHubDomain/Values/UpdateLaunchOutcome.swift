import Foundation

package enum UpdateLaunchOutcome: Equatable, Sendable {
    case nothing
    case clearStatus
    case updated(commit: String)
    case failed(message: String)
    case running(UpdateStatus)
    case stopped
}
