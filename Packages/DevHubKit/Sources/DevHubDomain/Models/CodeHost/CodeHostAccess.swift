import Foundation

package struct CodeHostAccess: Hashable, Sendable {
    package var login: String?
    package var scopes: [String]?

    package init(login: String?, scopes: [String]?) {
        self.login = login
        self.scopes = scopes
    }
}
