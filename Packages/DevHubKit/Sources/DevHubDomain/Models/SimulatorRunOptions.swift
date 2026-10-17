import Foundation

package struct SimulatorRunOptions: Codable, Hashable, Sendable {
    package var scheme: String
    package var configuration: String
    package var incremental: Bool
    package var cleanInstall: Bool
    package var source: BuildSourceChoice
    package var profileID: String?

    package init(
        scheme: String,
        configuration: String,
        incremental: Bool,
        cleanInstall: Bool,
        source: BuildSourceChoice,
        profileID: String?
    ) {
        self.scheme = scheme
        self.configuration = configuration
        self.incremental = incremental
        self.cleanInstall = cleanInstall
        self.source = source
        self.profileID = profileID
    }
}
