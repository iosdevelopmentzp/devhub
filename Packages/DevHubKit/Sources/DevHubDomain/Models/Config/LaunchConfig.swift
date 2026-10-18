import Foundation

package struct LaunchConfig: Codable, Hashable, Sendable {
    package var profiles: [LaunchProfile]? = nil
    package var identity: LaunchIdentityConfig? = nil

    package init(
        profiles: [LaunchProfile]? = nil,
        identity: LaunchIdentityConfig? = nil
    ) {
        self.profiles = profiles
        self.identity = identity
    }
}
