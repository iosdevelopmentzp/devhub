import Foundation

package struct LaunchIdentityConfig: Codable, Hashable, Sendable {
    package static let defaultPrefix = "devhub-"

    package var variable: String
    package var keptVariable: String? = nil
    package var args: [String]? = nil
    package var idPrefix: String? = nil
    package var cleanInstallOnChange: Bool? = nil
    package var hookMarker: String? = nil

    package init(
        variable: String,
        keptVariable: String? = nil,
        args: [String]? = nil,
        idPrefix: String? = nil,
        cleanInstallOnChange: Bool? = nil,
        hookMarker: String? = nil
    ) {
        self.variable = variable
        self.keptVariable = keptVariable
        self.args = args
        self.idPrefix = idPrefix
        self.cleanInstallOnChange = cleanInstallOnChange
        self.hookMarker = hookMarker
    }

    package var marker: String {
        hookMarker ?? variable
    }

    package var cleansOnChange: Bool {
        cleanInstallOnChange ?? true
    }

    package func newIdentity(uuid: UUID) -> String {
        (idPrefix ?? Self.defaultPrefix) + uuid.uuidString.prefix(8).lowercased()
    }
}
