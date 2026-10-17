import Foundation

package struct LaunchProfile: Codable, Hashable, Sendable, Identifiable {
    package var id: String
    package var title: String
    package var env: [String: String]? = nil
    package var args: [String]? = nil
    package var defaults: [ProfileDefault]? = nil
    package var cleanInstall: Bool? = nil

    package init(
        id: String,
        title: String,
        env: [String: String]? = nil,
        args: [String]? = nil,
        defaults: [ProfileDefault]? = nil,
        cleanInstall: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.env = env
        self.args = args
        self.defaults = defaults
        self.cleanInstall = cleanInstall
    }
}
