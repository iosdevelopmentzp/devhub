import Foundation

package struct AppStateReport: Hashable, Sendable {
    package var identity: String?
    package var profile: String?
    package var host: String?
    package var user: String?
    package var version: String?

    package init(
        identity: String?,
        profile: String?,
        host: String?,
        user: String?,
        version: String?
    ) {
        self.identity = identity
        self.profile = profile
        self.host = host
        self.user = user
        self.version = version
    }
}
