import Foundation
import DevHubDomain
import DevHubUI

struct ConfigActionRun: Hashable {
    enum Status: Hashable {
        case running
        case succeeded
        case failed(String)
        case cancelled
    }

    var status: Status
    var startedAt: Date
    var finishedAt: Date?
    var view: ScriptView?

    var failureMessage: String? {
        guard case let .failed(message) = status else { return nil }
        return message
    }

    var isRunning: Bool {
        status == .running
    }
}
