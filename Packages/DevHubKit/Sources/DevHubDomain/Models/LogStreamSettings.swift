import Foundation

package struct LogStreamSettings: Codable, Hashable, Sendable {
    package var udid: String
    package var name: String
    package var process: String
    package var subsystem: String
    package var level: Int

    package init(
        udid: String,
        name: String,
        process: String,
        subsystem: String,
        level: Int
    ) {
        self.udid = udid
        self.name = name
        self.process = process
        self.subsystem = subsystem
        self.level = level
    }
}
