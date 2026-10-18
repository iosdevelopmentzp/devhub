import Foundation

package struct LaunchRecord: Codable, Hashable, Sendable {
    package var profileID: String?
    package var identity: String?
    package var baseURL: String?
    package var date: Date

    package init(
        profileID: String?,
        identity: String?,
        baseURL: String?,
        date: Date
    ) {
        self.profileID = profileID
        self.identity = identity
        self.baseURL = baseURL
        self.date = date
    }
}
