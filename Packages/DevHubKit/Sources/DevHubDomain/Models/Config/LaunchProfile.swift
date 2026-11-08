import Foundation

package struct LaunchProfile: Codable, Hashable, Sendable, Identifiable {
    package var id: String
    package var title: String
    package var env: [String: String]? = nil
    package var args: [String]? = nil
    package var defaults: [ProfileDefault]? = nil
    package var cleanInstall: Bool? = nil
    package var storage: ProfileStorage? = nil
    package var upstream: String? = nil
    package var routes: [ProfileRoute]? = nil
    package var production: Bool? = nil
    package var tint: ConfigTint? = nil

    package init(
        id: String,
        title: String,
        env: [String: String]? = nil,
        args: [String]? = nil,
        defaults: [ProfileDefault]? = nil,
        cleanInstall: Bool? = nil,
        storage: ProfileStorage? = nil,
        upstream: String? = nil,
        routes: [ProfileRoute]? = nil,
        production: Bool? = nil,
        tint: ConfigTint? = nil
    ) {
        self.id = id
        self.title = title
        self.env = env
        self.args = args
        self.defaults = defaults
        self.cleanInstall = cleanInstall
        self.storage = storage
        self.upstream = upstream
        self.routes = routes
        self.production = production
        self.tint = tint
    }

    package var isProduction: Bool {
        production ?? false
    }
}
