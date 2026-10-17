import Foundation

package enum PipelineStatePolicy {

    package static func isActive(_ status: CheckStatus) -> Bool {
        switch status {
        case .running, .pending, .created, .waitingForResource, .preparing, .scheduled: true
        default: false
        }
    }
}
