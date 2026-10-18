import Foundation

package struct AppLogFilter: Hashable, Sendable {
    package var process: String
    package var subsystem: String

    package init(
        process: String,
        subsystem: String
    ) {
        self.process = process
        self.subsystem = subsystem
    }

    package var isEmpty: Bool {
        process.trimmed.isEmpty && subsystem.trimmed.isEmpty
    }
}
