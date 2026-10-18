import Foundation
import DevHubDomain
import DevHubUI

nonisolated package struct CommandLogRecorder: CommandRecording {
    let log: CommandLog

    package init(log: CommandLog) {
        self.log = log
    }

    package func record(_ event: CommandEvent) {
        DispatchQueue.main.async { @MainActor in
            log.handle(event)
        }
    }
}
