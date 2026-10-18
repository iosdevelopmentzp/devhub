import Foundation

package struct SimulatorLaunchSettings: Codable, Hashable, Sendable {
    package static let empty = SimulatorLaunchSettings(desiredIdentity: nil, appliedIdentity: nil, hasApplied: false, lastLaunch: nil)

    package var desiredIdentity: String?
    package var appliedIdentity: String?
    package var hasApplied: Bool
    package var lastLaunch: LaunchRecord?

    package init(
        desiredIdentity: String?,
        appliedIdentity: String?,
        hasApplied: Bool,
        lastLaunch: LaunchRecord?
    ) {
        self.desiredIdentity = desiredIdentity
        self.appliedIdentity = appliedIdentity
        self.hasApplied = hasApplied
        self.lastLaunch = lastLaunch
    }

    package var actualIdentity: String? {
        hasApplied ? appliedIdentity : nil
    }
}
