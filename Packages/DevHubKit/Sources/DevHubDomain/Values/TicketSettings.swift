import Foundation

package struct TicketSettings: Hashable, Sendable {
    package var pattern: String
    package var format: String
    package var urlTemplate: String

    package static let standard = TicketSettings(
        pattern: GitSettingsPolicy.defaultTicketPattern,
        format: GitSettingsPolicy.defaultTicketFormat,
        urlTemplate: ""
    )

    package init(pattern: String, format: String, urlTemplate: String) {
        self.pattern = pattern
        self.format = format
        self.urlTemplate = urlTemplate
    }
}
