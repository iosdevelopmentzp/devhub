import Foundation

package struct ScriptAction: Identifiable, Hashable, Sendable {
    package let id: String
    package var title: String
    package var subtitle: String
    package var fileName: String
    package var systemImage: String
    package var lastRun: Date?

    package init(id: String, title: String, subtitle: String, fileName: String, systemImage: String, lastRun: Date?) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.fileName = fileName
        self.systemImage = systemImage
        self.lastRun = lastRun
    }
}
