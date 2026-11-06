import Foundation

package struct AppStateReport: Hashable, Sendable {
    package var identity: String?
    package var profile: String?
    package var host: String?
    package var user: String?
    package var version: String?
    package var tags: [ScriptViewTag] = []

    package init(
        identity: String?,
        profile: String?,
        host: String?,
        user: String?,
        version: String?,
        tags: [ScriptViewTag] = []
    ) {
        self.identity = identity
        self.profile = profile
        self.host = host
        self.user = user
        self.version = version
        self.tags = tags
    }
}
