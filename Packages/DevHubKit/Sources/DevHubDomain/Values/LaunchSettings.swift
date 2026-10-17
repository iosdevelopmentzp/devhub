import Foundation

package struct LaunchSettings: Hashable, Sendable {
    package static let none = LaunchSettings(environment: [:], arguments: [], defaults: [])

    package var environment: [String: String]
    package var arguments: [String]
    package var defaults: [ProfileDefault]

    package init(environment: [String: String], arguments: [String], defaults: [ProfileDefault]) {
        self.environment = environment
        self.arguments = arguments
        self.defaults = defaults
    }

    package init(profile: LaunchProfile?) {
        self.init(environment: profile?.env ?? [:], arguments: profile?.args ?? [], defaults: profile?.defaults ?? [])
    }
}
