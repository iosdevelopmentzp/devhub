import Foundation

package enum PipelineStatePolicy {

    package static func isActive(_ status: PipelineStatus) -> Bool {
        switch status {
        case .running, .pending, .created, .waitingForResource, .preparing, .scheduled: true
        default: false
        }
    }
}
