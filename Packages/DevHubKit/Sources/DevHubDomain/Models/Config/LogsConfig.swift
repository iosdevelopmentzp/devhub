import Foundation

package struct LogsConfig: Codable, Hashable, Sendable {
    package var process: String? = nil
    package var subsystem: String? = nil

    package init(
        process: String? = nil,
        subsystem: String? = nil
    ) {
        self.process = process
        self.subsystem = subsystem
    }
}
