import Foundation

package struct LaunchConfig: Codable, Hashable, Sendable {
    package var profiles: [LaunchProfile]? = nil

    package init(
        profiles: [LaunchProfile]? = nil
    ) {
        self.profiles = profiles
    }
}
