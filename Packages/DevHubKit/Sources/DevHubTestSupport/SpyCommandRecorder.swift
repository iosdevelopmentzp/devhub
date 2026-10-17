import DevHubDomain
import Foundation

package final class SpyCommandRecorder: CommandRecording, @unchecked Sendable {
    private let lock = NSLock()
    private var _events: [CommandEvent] = []

    package init() {}

    package var events: [CommandEvent] {
        lock.withLock { _events }
    }

    package func record(_ event: CommandEvent) {
        lock.withLock { _events.append(event) }
    }
}
